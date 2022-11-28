//
//  AppDelegate.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/28.
//

import UIKit
import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // IQKeyboardManagerSwift
        IQKeyboardManager.shared.enable = true

        // cocoa pods安裝完Firebase後補上如下
        FirebaseApp.configure()

        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor().hexStringToUIColor(hex: "1b4464")
        // navigation bar title顏色
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor().hexStringToUIColor(hex: "f2f6f7")]
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        // navigation bar push的返回箭頭顏色
        UINavigationBar.appearance().tintColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor =  UIColor().hexStringToUIColor(hex: "1b4464")
        UITabBar.appearance().tintColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
