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
        view.addSubview(signInButton)
        signInButton.addTarget(self, action: #selector(didTapSignIn), for: .touchUpInside)
        cancelSignIn()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        if KeychainWrapper.standard.string(forKey: "id") != nil {
//            self.presentingViewController?.dismiss(animated: true, completion: nil)
//        }
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

    // 取消登入按鈕trigger
    func cancelSignIn() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(dismissSignInPage))
    }

    // 取消並dismiss VC
    @objc func dismissSignInPage() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
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
//    self.presentingViewController?.dismiss(animated: true, completion: nil)

//    // 從Firebase上fetch全部user資料，並append到userContent裡
//    func fetchUser() {
//        let dataBase = Firestore.firestore()
//        dataBase.collection("user")
//            .getDocuments { snapshot, error in
//                guard let snapshot = snapshot else {
//                    return
//                }
//                let user = snapshot.documents.compactMap { snapshot in
//                    try? snapshot.data(as: User.self)
//                }
//
//                // 把fetch下來的user data append到userContent的array中
//                self.userContent.append(contentsOf: user)
//            }
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
            // 當email不為空時表示使用者為第一次登入，故新增使用者資訊
            if email != nil {
                createUserIdentify(id: credentials.user, email: email ?? "", name: (lastName ?? "") + (firstName ?? ""))
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
