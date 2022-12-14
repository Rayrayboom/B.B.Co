//
//  TabViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/31.
//

import UIKit
import SwiftKeychainWrapper

class TabViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
}

// 當點選第1個tab bar時會present AddNewDataVC
extension TabViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let viewControllers = tabBarController.viewControllers {
            // 當tabBar點選到第二個時，present addNewData page
            if viewController == viewControllers[2] {
                if KeychainWrapper.standard.string(forKey: "id") == nil {
                    let storyboard = UIStoryboard(name: "Home", bundle: nil)
                    guard let presentSignInVC = storyboard.instantiateViewController(withIdentifier: "signInVC") as? SignInViewController
                    else {
                        fatalError("ERROR: Can not find signIn page")
                    }
                    let navigation = UINavigationController(rootViewController: presentSignInVC)
                    navigation.modalPresentationStyle = .fullScreen
                    present(navigation, animated: true, completion: nil)
                    return false
                } else {
                    let storyboard = UIStoryboard(name: "AddNewData", bundle: nil)
                    guard let presentAddNewData = storyboard.instantiateViewController(
                        withIdentifier: /*"calculateVC"*/ "addNewData") as? AddNewDataViewController //CalculateViewController
                    else {
                        fatalError("ERROR: Can not find addNewData page.")
                    }
                    let navigation = UINavigationController(rootViewController: presentAddNewData)
                    navigation.modalPresentationStyle = .fullScreen
                    present(navigation, animated: true, completion: nil)
                    return false
                }
            } else if viewController == viewControllers[1] || viewController == viewControllers[3] {
                if KeychainWrapper.standard.string(forKey: "id") == nil {
                    // 當tabBar點選到第一個時，需要使用者登入才可以使用co-account功能(present sign_in page)
                    let storyboard = UIStoryboard(name: "Home", bundle: nil)
                    guard let presentSignInVC = storyboard.instantiateViewController(withIdentifier: "signInVC") as? SignInViewController
                    else {
                        fatalError("ERROR: Can not find signIn page")
                    }
                    let navigation = UINavigationController(rootViewController: presentSignInVC)
                    navigation.modalPresentationStyle = .fullScreen
                    present(navigation, animated: true, completion: nil)
                    return false
                }
            }
        }
        return true
    }
}
