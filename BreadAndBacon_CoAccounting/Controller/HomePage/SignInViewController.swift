//
//  SignInViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/15.
//
import AuthenticationServices
import UIKit
import FirebaseFirestore

class SignInViewController: UIViewController {
    private let signInButton = ASAuthorizationAppleIDButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(signInButton)
        signInButton.addTarget(self, action: #selector(didTapSignIn), for: .touchUpInside)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        signInButton.frame = CGRect(x: 0, y: 0, width: 250, height: 50)
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

    func createUserIdentify(id: String, email: String, name: String) {
        let dataBase = Firestore.firestore()
        let userID = dataBase.collection("user")
        let identifier = userID.document(id)
        let collection = User(id: id, email: email, name: name)

        do {
            try identifier.setData(from: collection)
            print("success create user document ID: \(identifier)")
        } catch {
            print(error)
        }
    }

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
        print("sign in faild")
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let credentials as ASAuthorizationAppleIDCredential:
            let firstName = credentials.fullName?.givenName
            let lastName = credentials.fullName?.familyName
            let email = credentials.email
            createUserIdentify(id: credentials.user, email: email ?? "", name: (lastName ?? "") + (firstName ?? ""))
            print(credentials.user)
            print(firstName)
            print(lastName)
            print(email)

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
