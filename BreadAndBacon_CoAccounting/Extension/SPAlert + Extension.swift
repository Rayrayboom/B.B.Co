//
//  SucessAlert.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/21.
//

import Foundation
import SPAlert

extension SPAlert {
    static func successAlert() {
        let alertView = SPAlertView(title: "Success", preset: .done)
        alertView.iconView?.tintColor = .systemBrown
        alertView.layout.iconSize = .init(width: 100, height: 100)
        alertView.layout.margins.top = 40
        alertView.layout.spaceBetweenIconAndTitle = 5
        SPAlertView.appearance().duration = 1
        SPAlertView.appearance().cornerRadius = 50
        alertView.duration = 1
        alertView.present()
    }
}
