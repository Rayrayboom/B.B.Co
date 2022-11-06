//
//  BBCoDateFormatter.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/3.
//

import Foundation

class BBCDateFormatter {
    // 因為DateFormatter()非常佔記憶體也很吃效能，因此把它從VC拉出來，用成static，只要有其他class要用到的話直接BBCDateFormatter.shareFormatter即可用
    static let shareFormatter = DateFormatter()
}
