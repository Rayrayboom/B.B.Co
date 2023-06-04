//
//  HomeViewModel.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2023/2/9.
//

import Foundation
import SwiftKeychainWrapper

protocol HomeViewModelDelegate: AnyObject {
    func doThingsAfterFetchedData()
}

struct HomeViewModel {
    weak var delegate: HomeViewModelDelegate?
    let data = Observable([Account]())
    var getId: String = ""
    var indexPathRow:Int = 0
    
    init() {
        getId = KeychainWrapper.standard.string(forKey: "id") ?? ""
    }
    
    func fetchAllData(date: Date) {
        let group = DispatchGroup()
        let subCollection = ["expenditure", "revenue", "account"]

        for num in subCollection {
            group.enter()
            BBCoFireBaseManager.shared.fetchUserSpecific(id: getId, subCollection: num, date: date) { result in
                data.value = []
                data.value += result
                group.leave()
            }
        }

        group.notify(queue: .main) {
            delegate?.doThingsAfterFetchedData()
        }
    }
    
    func deleteSpecificData(indexPathRow: Int) {
        BBCoFireBaseManager.shared.deleteSpecificData(id: getId, subCollection: SubCategory.expenditure, dataId: data.value[indexPathRow].id)
        BBCoFireBaseManager.shared.deleteSpecificData(id: getId, subCollection: SubCategory.revenue, dataId: data.value[indexPathRow].id)
        BBCoFireBaseManager.shared.deleteSpecificData(id: getId, subCollection: SubCategory.account, dataId: data.value[indexPathRow].id)

        data.value.remove(at: indexPathRow)
    }
    
    
}
