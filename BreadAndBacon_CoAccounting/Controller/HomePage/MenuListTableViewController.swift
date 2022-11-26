//
//  MenuListTableViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/23.
//

import UIKit
import FirebaseFirestore
import SwiftKeychainWrapper
import SwiftJWT
import SwiftUI
import SafariServices

struct MyClaim: Claims {
    let iss: String
    let sub: String
    let exp: Date
    let aud: String
}

// 建立side menu tableView
class MenuListTableViewController: UITableViewController {
    var items = ["支出種類", "收入種類", "帳戶種類", "隱私權條款", "登出 及 刪除帳號"]
    let darkColor = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1)
    // 存keychain user id
    var getId: String = ""
    // 存keychain user name
    var getName: String = ""
    var alertController = UIAlertController()
    // 存JWT
    var signedJWT: String = ""
    var group = DispatchGroup()
    // 用來存現有的user
    var bookContent: [Book] = []
    // 用來存user name
    var userName: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        getId = KeychainWrapper.standard.string(forKey: "id") ?? ""
        getName = KeychainWrapper.standard.string(forKey: "name") ?? ""
        tableView.backgroundColor = darkColor
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "personalCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "sideMenuCategoryCell")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        default:
            return items.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let personalCell = tableView.dequeueReusableCell(withIdentifier: "personalCell", for: indexPath)
            personalCell.textLabel?.text = "哈囉~ \(getName)"
            personalCell.textLabel?.textColor = .white
            personalCell.backgroundColor = darkColor

            return personalCell
        default:
            let sideMenuCategoryCell = tableView.dequeueReusableCell(withIdentifier: "sideMenuCategoryCell", for: indexPath)
            sideMenuCategoryCell.textLabel?.text = items[indexPath.row]
            sideMenuCategoryCell.textLabel?.textColor = .white
            sideMenuCategoryCell.backgroundColor = darkColor

            return sideMenuCategoryCell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 點選cell時觸發點選效果
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.section {
        case 0:
            print("side menu")
        default:
            switch indexPath.row {
            case 3: // show privacy
                let homeStoryboard = UIStoryboard(name: "Home", bundle: nil)
                guard let presentPrivacyVC = homeStoryboard
                    .instantiateViewController(withIdentifier: "privacyVC") as? PrivacyViewController
                else {
                    fatalError("can not present privacyVC")
                }
                presentPrivacyVC.modalPresentationStyle = .automatic
                present(presentPrivacyVC, animated: true)
            case 4: // sign out and delete account
                signOutAlert()
            default: // category list
                // 先指定storyboard(避免self.storyboard為nil的狀況)
                let homeStoryboard = UIStoryboard(name: "Home", bundle: nil)
                guard let presentCategoryVC = homeStoryboard
                    .instantiateViewController(withIdentifier: "categoryVC") as? CategoryViewController
                else {
                    fatalError("can not present categoryVC")
                }

                presentCategoryVC.indexPathRow = indexPath.row
                presentCategoryVC.modalPresentationStyle = .automatic
                present(presentCategoryVC, animated: true)
            }
        }
    }

    // 登出跳出下方選單
    func signOutAlert() {
        alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let name = "登出"
        let action = UIAlertAction(title: name, style: .default) { action in
            KeychainWrapper.standard.remove(forKey: "id")
            KeychainWrapper.standard.remove(forKey: "name")

            print("this is user id", KeychainWrapper.standard.string(forKey: "id") ?? "")
            print("this is user name", KeychainWrapper.standard.string(forKey: "name") ?? "")
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = mainStoryboard.instantiateViewController(withIdentifier: "signInVC") as! SignInViewController
            UIApplication.shared.windows.first?.rootViewController = viewController
            UIApplication.shared.windows.first?.makeKeyAndVisible()
        }
        alertController.addAction(action)

        // 刪除帳號alert
        let deleteAction = UIAlertAction(title: "刪除帳號", style: UIAlertAction.Style.destructive) { action in
            // 當選擇刪除帳號後讓使用者做最後確認alert
            let doubleCheckController = UIAlertController(title: "確定要刪除帳號嗎？", message: "刪除帳號後，個人及共同帳本之備份資料將會全部清除", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "確定", style: .destructive) { action in
                // 刪除user底下所有的subCollection document
                self.deleteAllSubCollectionDoc()
                // 刪除co-account所有有關這個使用者的資料(但不刪除尚有其他user_id的帳本)
                self.deleteCoAccoount()
                // 刪除user document
                self.deleteUser()
                // 打revoke token API
                self.removeAccount()
                KeychainWrapper.standard.remove(forKey: "id")
                KeychainWrapper.standard.remove(forKey: "name")
                KeychainWrapper.standard.remove(forKey: "refreshToken")

                print("this is user id", KeychainWrapper.standard.string(forKey: "id") ?? "")
                print("this is user name", KeychainWrapper.standard.string(forKey: "name") ?? "")
                print("this is refreshToken", KeychainWrapper.standard.string(forKey: "refreshToken") ?? "")

                let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let viewController = mainStoryboard.instantiateViewController(withIdentifier: "signInVC") as! SignInViewController
                UIApplication.shared.windows.first?.rootViewController = viewController
                UIApplication.shared.windows.first?.makeKeyAndVisible()
            }
            doubleCheckController.addAction(okAction)

            let cancelAction = UIAlertAction(title: "再想想", style: .cancel)
            doubleCheckController.addAction(cancelAction)
            self.present(doubleCheckController, animated: true, completion: nil)
        }
        alertController.addAction(deleteAction)

        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }

    // gen JWT token
    func makeSwiftJWT() {
        let myHeader = Header(kid: APIKey.authKey)
        let myClaims = MyClaims(iss: APIKey.teamID, sub: APIKey.bundleID, exp: Date(timeIntervalSinceNow: 120), aud: "https://appleid.apple.com")
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

    // 打revoke token API
    func removeAccount() {
        // 先產生一組新的JWT
        makeSwiftJWT()
        // 取回keyChain裡的refreshTocken
        let token = KeychainWrapper.standard.string(forKey: "refreshToken")

        if let token = token {
            let url = URL(string: "https://appleid.apple.com/auth/revoke?client_id=\(APIKey.bundleID)&client_secret=\(signedJWT)&token=\(token)&token_type_hint=refresh_token".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "https://apple.com")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
                if let error = error {
                    print(fatalError("can not delete account"))
                }

                guard let response = response as? HTTPURLResponse,
                        response.statusCode == 200 else {
                    print("response error")
                    return
                }

                guard data != nil else { return }
            }
            task.resume()
        }
    }

    // TODO: - 刪除個人（個人資訊+個人記帳細項）
    // 從firebase上刪除資料，delete firebase data需要一層一層找，不能用路徑
    func deleteUser() {
        let dataBase = Firestore.firestore()
        let documentRef = dataBase.collection("user").document(getId)
        documentRef.delete()
    }

    // 刪除個人記帳單一subCollection底下所有的資料
    func deleteSubCollectionDoc(subCollection: String) {
        let dataBase = Firestore.firestore()
        let documentRef = dataBase.collection("user").document(getId).collection(subCollection)
        documentRef.getDocuments { querySnapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                guard let querySnapshot = querySnapshot else {
                    return
                }
                for document in querySnapshot.documents {
                    print("=== this is documentID \(document.documentID)")
                    document.reference.delete()
                }
            }
        }
    }

    // 刪除個人記帳subcollection所有的資料
    func deleteAllSubCollectionDoc() {
        deleteSubCollectionDoc(subCollection: "expenditure")
        deleteSubCollectionDoc(subCollection: "expenditure_category")
        deleteSubCollectionDoc(subCollection: "revenue")
        deleteSubCollectionDoc(subCollection: "revenue_category")
        deleteSubCollectionDoc(subCollection: "account")
        deleteSubCollectionDoc(subCollection: "account_category")
    }

    // TODO: - 刪除共同帳本（共同帳本付款者）
    func deleteCoAccoount() {
        bookContent = []
        let dataBase = Firestore.firestore()
        self.group.enter()
        // 先搜尋co-account裡有哪些book包含getName(付款人-userName)
        dataBase.collection("co-account").whereField("user_id", arrayContains: getName)
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let book = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Book.self)
                }
                self.bookContent.append(contentsOf: book)
                print("=== is bookContent", self.bookContent)
                self.group.leave()
            }
        group.notify(queue: .main) {
            // 把有包含我的book用forEach一個一個找，如果user_id == 1表示我刪除帳號後這本帳本也就失效，因此連同帳本一併刪除; 若user_id超過一人，表示還有其他使用者在這本帳本裡，因此只執行把我自己從付款者裡移除
            self.bookContent.forEach { item in
                if item.userId.count == 1 {
                    print("=== item.userId isEmpty")
                    let documentRef = dataBase.collection("co-account").document(item.id)
                    documentRef.delete()
                } else {
                    dataBase.collection("co-account")
                        .document(item.id)
                        .updateData(["user_id": FieldValue.arrayRemove([self.getName])])
                    print("=== is item.userId", item.userId)
                }
            }
        }
    }
}
