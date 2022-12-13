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
    // 存JWT
    var signedJWT: String = ""
    // alertController
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
        // 判斷當使用者已登入後，重開app不需再登入一次，因為登出會刪掉keychain的user id，故用這個條件來判斷
        if (KeychainWrapper.standard.string(forKey: "id") != nil) {
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = mainStoryboard.instantiateViewController(withIdentifier: "tabBarVC") as! UITabBarController
            UIApplication.shared.windows.first?.rootViewController = viewController
            UIApplication.shared.windows.first?.makeKeyAndVisible()
        } else {
            // 先把sign in button加入畫面
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
        // 按下登入時取得JWT token
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

    // 取得refresh token，並存在keyChain裡
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
            // authorizationCode每次登入都不一樣, ex. cb4ea06aa72c7454985548506dda2883a.0.rrsyu.J0e-UzcZTROUwW75Z_1Haw
            if let authorizationCode = credentials.authorizationCode,
               let codeString = String(data: authorizationCode, encoding: .utf8) {
                getRefreshToken(codeString: codeString)
            }

            // first login
            if let firstName = firstName, let lastName = lastName {
                // 把user id存在ketchain的"id"這個key裡(key-value的概念)
                KeychainWrapper.standard.set(user, forKey: "id")
                // 把user name存在ketchain的"name"這個key裡(key-value的概念)-只有第一次apple會給值
                KeychainWrapper.standard.set((lastName ?? "") + (firstName ?? ""), forKey: "name")
                let dataBase = Firestore.firestore()
                let docRef = dataBase.collection("user").document(user)
                // 判斷user裡的document有沒有對應的user id，不存在表示沒有建立過帳號，接著建立一筆user document; 反之，若現有帳號已存在則直接導入畫面
                docRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                        print("Document data: \(dataDescription)")
                    } else {
                        print("Document does not exist")
                        BBCoFireBaseManager.shared.createUserIdentify(id: user, email: email ?? "", name: (lastName ?? "") + (firstName ?? ""))
                    }
                }
                // 判斷若是第一次登入的話就先create三大種類的category，讓使用者一開始有預設選項可以用
                createAllCategory()
            }

            // second login
            else {
                // TODO: - get name -> vc name
                // TODO: - get name from firebase "id"
                let dataBase = Firestore.firestore()
                let docRef = dataBase.collection("user").document(user)
                // 判斷user裡的document有沒有對應的user id，有的話表示已登入過，直接進到user document拿user name(因為第二次登入後apple不會再給name,email)，不存在表示沒有建立過帳號
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
                // TODO: - keychain set name
                // 把user id存在ketchain的"id"這個key裡(key-value的概念)
                KeychainWrapper.standard.set(user, forKey: "id")
            }

            // 測試是否拿到資料
//            print("ggggg", getId)
//            print(credentials.user)
//            print(firstName)
//            print(lastName)
//            print(email)
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = mainStoryboard.instantiateViewController(withIdentifier: "tabBarVC") as! UITabBarController
            UIApplication.shared.windows.first?.rootViewController = viewController
            UIApplication.shared.windows.first?.makeKeyAndVisible()

            break
        default:
            break
        }
    }

    // 一次新增全部category
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
