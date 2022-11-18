//
//  PersonalViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/16.
//

import UIKit
import SwiftKeychainWrapper

class PersonalViewController: UIViewController {
    // 登出後先移除keychain上的user id/user name，接著跳轉回登入頁面
    @IBAction func signOut(_ sender: UIButton) {
        KeychainWrapper.standard.remove(forKey: "id")
        KeychainWrapper.standard.remove(forKey: "name")

        print("this is user id", KeychainWrapper.standard.string(forKey: "id"))
        print("this is user name", KeychainWrapper.standard.string(forKey: "name"))
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainStoryboard.instantiateViewController(withIdentifier: "signInVC") as! SignInViewController
        UIApplication.shared.windows.first?.rootViewController = viewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
