//
//  UIStoryboard+Extension.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/31.
//

import Foundation
import UIKit

private struct StoryboardCategory {
    static let addNewData = "AddNewData"
}


extension UIStoryboard {
    static var addNewData: UIStoryboard { return goToStoryboard(name: StoryboardCategory.addNewData) }
    private static func goToStoryboard(name: String) -> UIStoryboard {
        return UIStoryboard(name: name, bundle: nil)
    }
}
