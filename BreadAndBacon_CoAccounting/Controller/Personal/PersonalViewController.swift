//
//  PersonalViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/16.
//

import UIKit
import SwiftKeychainWrapper

class PersonalViewController: UIViewController {
    @IBAction func signOut(_ sender: UIButton) {
        KeychainWrapper.standard.remove(forKey: "id")
        print("this is user id", KeychainWrapper.standard.string(forKey: "id"))
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainStoryboard.instantiateViewController(withIdentifier: "signInVC") as! SignInViewController
        UIApplication.shared.windows.first?.rootViewController = viewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
