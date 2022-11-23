//
//  MenuListTableViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/23.
//

import UIKit
import SwiftKeychainWrapper

// 建立side menu tableView
class MenuListTableViewController: UITableViewController {
    var items = ["支出種類", "收入種類", "帳戶種類", "登出"]
    let darkColor = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1)
    var getName: String = ""
    var alertController = UIAlertController()

    override func viewDidLoad() {
        super.viewDidLoad()
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
            case 3: // sign out
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
            print(action.title ?? "")
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

        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}
