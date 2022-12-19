//
//  SignInViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/15.
//
import AuthenticationServices
import UIKit
import FirebaseFirestore
import SwiftKeychainWrapper
import SwiftJWT

struct MyClaims: Claims {
    let iss: String
    let sub: String
    let exp: Date
    let aud: String
}

class SignInViewController: UIViewController {
    private let signInButton = ASAuthorizationAppleIDButton()
    var userData = ""
    // store JWT
    var signedJWT: String = ""
    var controller = UIAlertController()
    var costContent: [String] = ["早餐", "午餐", "晚餐", "宵夜" ]
    var incomeContent: [String] = ["現金", "獎金"]
    var accountContent: [String] = ["現金"]

    @IBOutlet weak var BBCoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBAction func showPrivacy(_ sender: UIButton) {
        let homeStoryboard = UIStoryboard(name: "Home", bundle: nil)
        guard let presentPrivacyVC = homeStoryboard
            .instantiateViewController(withIdentifier: "privacyVC") as? PrivacyViewController
        else {
            fatalError("can not present privacyVC")
        }
        presentPrivacyVC.modalPresentationStyle = .fullScreen
        present(presentPrivacyVC, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if (KeychainWrapper.standard.string(forKey: "id") != nil) {
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = mainStoryboard.instantiateViewController(withIdentifier: "tabBarVC") as! UITabBarController
            UIApplication.shared.windows.first?.rootViewController = viewController
            UIApplication.shared.windows.first?.makeKeyAndVisible()
        } else {
            view.addSubview(signInButton)
            signInButton.addTarget(self, action: #selector(didTapSignIn), for: .touchUpInside)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupSignInUI()
    }

    // 設定titleLabel constrains
    func setupSignInUI() {
        titleLabel.text = "登入，為個人、共同帳本啟用同步和備份 功能"
        titleLabel.textColor = .lightGray
        signInButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            signInButton.widthAnchor.constraint(equalToConstant: 280),
            signInButton.heightAnchor.constraint(equalToConstant: 50),
            signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -150)
        ])
    }

    @objc func didTapSignIn() {
        // get JWT token when user press sign-in button
        makeSwiftJWT()
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // gen JWT token
    func makeSwiftJWT() {
        let myHeader = Header(kid: APIKey.authKey)
        let myClaims = MyClaims(iss: APIKey.teamID, sub: APIKey.bundleID, exp: Date(timeIntervalSinceNow: 12000), aud: "https://appleid.apple.com")
        var myJWT = JWT(header: myHeader, claims: myClaims)
        let privateKey = APIKey.privateKey
        do {
            let jwtSigner = JWTSigner.es256(privateKey: Data(privateKey.utf8))
            signedJWT = try myJWT.sign(using: jwtSigner)
            print("=== get JWT", signedJWT)
        } catch {
            print("can not get JWT")
        }
    }
}

extension SignInViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("sign in failed")
    }

    // get refresh token and store in keyChain
    func getRefreshToken(codeString: String) {
        let url = URL(string: "https://appleid.apple.com/auth/token?client_id=\(APIKey.bundleID)&client_secret=\(signedJWT)&grant_type=authorization_code&code=\(codeString)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "https://apple.com")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            if let error = error {
                print(fatalError("can not get refreshToken"))
            }

            guard let response = response as? HTTPURLResponse,
                    response.statusCode == 200 else {
                print("response error")
                return
            }

            if let data = data {
                let refreshToken = self.parseData(jsonData: data)
                KeychainWrapper.standard.set(refreshToken?.refreshToken ?? "", forKey: "refreshToken")
            }
        }
        task.resume()
    }

    func parseData(jsonData: Data) -> RefreshToken? {
        do {
            let result = try JSONDecoder().decode(RefreshToken.self, from: jsonData)
            return result
        } catch {
            print("=== result error")
            return nil
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let credentials as ASAuthorizationAppleIDCredential:
            let user = credentials.user
            let firstName = credentials.fullName?.givenName
            let lastName = credentials.fullName?.familyName
            let email = credentials.email
            if let authorizationCode = credentials.authorizationCode,
               let codeString = String(data: authorizationCode, encoding: .utf8) {
                getRefreshToken(codeString: codeString)
            }

            // first login
            if let firstName = firstName, let lastName = lastName {
                KeychainWrapper.standard.set(user, forKey: "id")
                KeychainWrapper.standard.set((lastName ?? "") + (firstName ?? ""), forKey: "name")
                let dataBase = Firestore.firestore()
                let docRef = dataBase.collection("user").document(user)
                docRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                        print("Document data: \(dataDescription)")
                    } else {
                        print("Document does not exist")
                        BBCoFireBaseManager.shared.createUserIdentify(id: user, email: email ?? "", name: (lastName ?? "") + (firstName ?? ""))
                    }
                }
                createAllCategory()
            }

            // second login
            else {
                let dataBase = Firestore.firestore()
                let docRef = dataBase.collection("user").document(user)
                docRef.getDocument { (document, error) in
                    if let document = document, document.exists,
                        let user = try? document.data(as: User.self)
                    {
                        self.userData = user.name ?? ""
                        KeychainWrapper.standard.set(self.userData, forKey: "name")
                    } else {
                        print("Document does not exist")
                    }
                }
                KeychainWrapper.standard.set(user, forKey: "id")
            }

            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = mainStoryboard.instantiateViewController(withIdentifier: "tabBarVC") as! UITabBarController
            UIApplication.shared.windows.first?.rootViewController = viewController
            UIApplication.shared.windows.first?.makeKeyAndVisible()

            break
        default:
            break
        }
    }

    func createAllCategory() {
        let allCategory = [costContent, incomeContent, accountContent]
        allCategory.forEach { content in
            for item in content {
                switch content {
                case costContent:
                    BBCoFireBaseManager.shared.createCategory(id: KeychainWrapper.standard.string(forKey: "id") ?? "", subCollection: "expenditure_category", content: item)
                case incomeContent:
                    BBCoFireBaseManager.shared.createCategory(id: KeychainWrapper.standard.string(forKey: "id") ?? "", subCollection: "revenue_category", content: item)
                default:
                    BBCoFireBaseManager.shared.createCategory(id: KeychainWrapper.standard.string(forKey: "id") ?? "", subCollection: "account_category", content: item)
                }
            }
        }
    }
}

extension SignInViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
