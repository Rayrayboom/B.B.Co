//
//  MenuListTableViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/23.
//

import UIKit
import SwiftKeychainWrapper
import SwiftJWT
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
    var getId: String = ""
    var getName: String = ""
    var alertController = UIAlertController()
    // store JWT
    var signedJWT: String = ""
    var group = DispatchGroup()
    var bookContent: [Book] = []
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

        let deleteAction = UIAlertAction(title: "刪除帳號", style: UIAlertAction.Style.destructive) { action in
            let doubleCheckController = UIAlertController(title: "確定要刪除帳號嗎？", message: "刪除帳號後，個人及共同帳本之備份資料將會全部清除", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "確定", style: .destructive) { action in
                self.deleteAllSubCollectionDoc()
                // delete all of user co-account data
                self.deleteCoAccount()
                // delete user document
                BBCoFireBaseManager.shared.deleteUser(userId: self.getId)
                // revoke token API
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

    // revoke token API
    func removeAccount() {
        // generate new JWT
        makeSwiftJWT()
        // get refreshTocken which in keyChain
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

    func deleteAllSubCollectionDoc() {
        BBCoFireBaseManager.shared.deleteSubCollectionDoc(userId: getId, subCollection: "expenditure")
        BBCoFireBaseManager.shared.deleteSubCollectionDoc(userId: getId, subCollection: "expenditure_category")
        BBCoFireBaseManager.shared.deleteSubCollectionDoc(userId: getId, subCollection: "revenue")
        BBCoFireBaseManager.shared.deleteSubCollectionDoc(userId: getId, subCollection: "revenue_category")
        BBCoFireBaseManager.shared.deleteSubCollectionDoc(userId: getId, subCollection: "account")
        BBCoFireBaseManager.shared.deleteSubCollectionDoc(userId: getId, subCollection: "account_category")
    }

    func deleteCoAccount() {
        bookContent = []
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            self.group.enter()
            BBCoFireBaseManager.shared.fetchUserAllCoBook(userName: self.getName) { result in
                switch result {
                case .success(let bookContentData):
                    self.bookContent = bookContentData
                    self.group.leave()
                case .failure(let error):
                    print(error.localizedDescription, "fetch coBook data error")
                    self.group.leave()
                }
                
            }
            self.group.wait()
            self.bookContent.forEach { item in
                self.group.enter()
                if item.userId.count == 1 {
                    BBCoFireBaseManager.shared.deleteCoBook(bookId: item.id) { [weak self] in
                        guard let self = self else { return }
                        self.group.leave()
                    }
                } else {
                    BBCoFireBaseManager.shared.deleteUserFromCoBook(bookId: item.id, userName: self.getName) { [weak self] in
                        guard let self = self else { return }
                        self.group.leave()
                    }
                }
            }
            self.group.notify(queue: .main) {}
        }
    }
}
