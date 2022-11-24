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

    @IBOutlet weak var BBCoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

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

    // swiftlint: disable line_length
    // gen JWT token
    func makeSwiftJWT() {
        let myHeader = Header(kid: APIKey.authKey)
        let myClaims = MyClaims(iss: APIKey.teamID, sub: APIKey.bundleID, exp: Date(timeIntervalSinceNow: 12000), aud: "https://appleid.apple.com")
        var myJWT = JWT(header: myHeader, claims: myClaims)
        let privateKey = APIKey.privateKey
        do {
            let jwtSigner = JWTSigner.es256(privateKey: Data(privateKey.utf8))
            let signedJWT = try myJWT.sign(using: jwtSigner)
            print("=== get JWT", signedJWT)
        } catch {
            print("can not get JWT")
        }
    }

    // 設定titleLabel constrains
    func setupSignInUI() {
        titleLabel.text = "登入，為個人、共同帳本啟用同步和備份 功能"
        titleLabel.textColor = .lightGray
        signInButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            signInButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 550),
            signInButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 50),
            signInButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -50),
            signInButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -250)
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

    // 建立使用者資料，document id設為user id(因為user id一人對應一組不會變)
    func createUserIdentify(id: String, email: String, name: String) {
        let dataBase = Firestore.firestore()
        // 建立firebase路徑
        let userID = dataBase.collection("user")
        // 於路徑中新增一筆document，document id為user id
        let identifier = userID.document(id)
        let collection = User(id: id, email: email, name: name)

        do {
            try identifier.setData(from: collection)
            print("success create user document ID: \(identifier)")
        } catch {
            print(error)
        }
    }
}

extension SignInViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("sign in failed")
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
                // 每次登入都不一樣, ex. cb4ea06aa72c7454985548506dda2883a.0.rrsyu.J0e-UzcZTROUwW75Z_1Haw
                print("===coddd", codeString)
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
                        self.createUserIdentify(id: user, email: email ?? "", name: (lastName ?? "") + (firstName ?? ""))
                    }
                }
                print("first", KeychainWrapper.standard.string(forKey: "name") ?? "")
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
}

extension SignInViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
