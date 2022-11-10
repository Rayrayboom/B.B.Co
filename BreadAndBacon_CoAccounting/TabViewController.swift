//
//  TabViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/31.
//

import UIKit

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
            // 當tabBar點選到第一個時，present addNewData page
            if viewController == viewControllers[2] {
                let storyboard = UIStoryboard(name: "AddNewData", bundle: nil)
                guard let presentAddNewData = storyboard.instantiateViewController(
                    withIdentifier: "addNewData") as? AddNewDataViewController
                else {
                    fatalError("ERROR: Can not find addNewData page.")
                }
                let navigation = UINavigationController(rootViewController: presentAddNewData)
                navigation.modalPresentationStyle = .fullScreen
                present(navigation, animated: true, completion: nil)
                return false
            }
        }
        return true
// MARK: - need to figure out
//        if viewController is PresentViewController {
//            print("in presentVC")
//            guard let presentAddNewData = self.storyboard?.instantiateViewController(withIdentifier: "addNewData") as? AddNewDataViewController else {
//                fatalError("ERROR: Can not find addNewData page.")
//            }
//
//            let navigation = UINavigationController(rootViewController: presentAddNewData)
//            navigation.modalPresentationStyle = .fullScreen
//            present(navigation, animated: true, completion: nil)
//            //            self.present(AddNewDataViewController(), animated: true)
//            return false
//        } else {
//            return true
//        }
    }
}
