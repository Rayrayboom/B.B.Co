//
//  BBCoLoading.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/30.
//

import Foundation
import UIKit
import JGProgressHUD

class BBCoLoading {
    static var hud = JGProgressHUD()
    
    static func loading(view: UIView) {
        hud.textLabel.text = "Loading"
        hud.show(in: view)
        hud.dismiss(afterDelay: 0.7)
    }
}
