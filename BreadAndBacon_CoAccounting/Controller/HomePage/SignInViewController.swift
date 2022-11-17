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

class SignInViewController: UIViewController {
    private let signInButton = ASAuthorizationAppleIDButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        // 判斷當使用者已登入後，重開app不需再登入一次，因為登出會刪掉keychain的user id，故用這個條件來判斷
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
        signInButton.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
        signInButton.center = view.center
    }

    @objc func didTapSignIn() {
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

    // 確認user是否為第一次登入
//    func checkUserAccount(id: String) {
//        let dataBase = Firestore.firestore()
//        let docRef = dataBase.collection("user").document(id)
//
//        docRef.getDocument { (document, error) in
//            if let document = document, document.exists {
//                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
//                print("Document data: \(dataDescription)")
//            } else {
//                print("Document does not exist")
//            }
//        }
//    }
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
            // 把user id存在ketchain的"id"這個key裡(key-value的概念)
            KeychainWrapper.standard.set(user, forKey: "id")
            // 從ketchain的"id"這個key裡取出user id(key-value的概念)
            let getId = KeychainWrapper.standard.string(forKey: "id")

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
