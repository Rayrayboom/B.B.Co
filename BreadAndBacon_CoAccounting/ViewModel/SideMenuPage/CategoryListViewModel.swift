//
//  CategoryListViewModel.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2023/1/13.
//

import Foundation
import SwiftKeychainWrapper

struct CategoryListViewModel {
    // 具有property observer功能的model
    let category = Observable([Category]())
    var getId: String = ""
    var indexPathRow: Int = 0

    init() {
        getId = KeychainWrapper.standard.string(forKey: "id") ?? ""
    }

    func fetchSideMenuCategory() {
        switch indexPathRow {
        case 0:
            BBCoFireBaseManager.shared.fetchSideMenuCategory(id: getId, subCollection: "expenditure") { result in
                category.value = result
            }
        case 1:
            BBCoFireBaseManager.shared.fetchSideMenuCategory(id: getId, subCollection: "revenue") { result in
                category.value = result
            }
        case 2:
            BBCoFireBaseManager.shared.fetchSideMenuCategory(id: getId, subCollection: "account") { result in
                category.value = result
            }
        default:
            break
        }
    }
    
    func editSideMenuCategory(detailRow: Int, textFieldContent: String) {
        switch indexPathRow {
        case 0:
            BBCoFireBaseManager.shared.editSideMenuCategory(id: getId, subCollection: "expenditure", indexPathRow: detailRow, dataId: category.value[detailRow].id ?? "", textField: textFieldContent)
        case 1:
            BBCoFireBaseManager.shared.editSideMenuCategory(id: getId, subCollection: "revenue", indexPathRow: detailRow, dataId: category.value[detailRow].id ?? "", textField: textFieldContent)
        case 2:
            BBCoFireBaseManager.shared.editSideMenuCategory(id: getId, subCollection: "account", indexPathRow: detailRow, dataId: category.value[detailRow].id ?? "", textField: textFieldContent)
        default:
            break
        }
    }

    func deleteSideMenuCategory(detailRow: Int) {
        switch indexPathRow {
        case 0:
            BBCoFireBaseManager.shared.deleteSideMenuCategory(id: getId, subCollection: "expenditure", indexPathRow: detailRow, dataId: category.value[detailRow].id ?? "")
        case 1:
            BBCoFireBaseManager.shared.deleteSideMenuCategory(id: getId, subCollection: "revenue", indexPathRow: detailRow, dataId: category.value[detailRow].id ?? "")
        case 2:
            BBCoFireBaseManager.shared.deleteSideMenuCategory(id: getId, subCollection: "account", indexPathRow: detailRow, dataId: category.value[detailRow].id ?? "")
        default:
            break
        }
        category.value.remove(at: detailRow)
    }
}
