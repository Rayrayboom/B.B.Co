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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}
