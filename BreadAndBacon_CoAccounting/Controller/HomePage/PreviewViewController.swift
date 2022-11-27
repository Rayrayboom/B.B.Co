//
//  PreviewViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/27.
//
import UIKit
import SwiftKeychainWrapper
import Lottie


class PreviewViewController: UIViewController {
    @IBAction func goToSignIn(_ sender: UIButton) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let presentSignInVC = mainStoryboard
            .instantiateViewController(withIdentifier: "signInVC") as? SignInViewController
        else {
            fatalError("can not present privacyVC")
        }
        presentSignInVC.modalPresentationStyle = .fullScreen
        present(presentSignInVC, animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // 判斷如果使用者已經登入過，就直接導到首頁
        if (KeychainWrapper.standard.string(forKey: "id") != nil) {
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = mainStoryboard.instantiateViewController(withIdentifier: "tabBarVC") as! UITabBarController
            UIApplication.shared.windows.first?.rootViewController = viewController
            UIApplication.shared.windows.first?.makeKeyAndVisible()
        }
    }
}
