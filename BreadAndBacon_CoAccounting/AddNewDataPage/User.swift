//
//  User.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/2.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct User: Codable {
    @DocumentID var documentID: String?
    let id: String
    let email: String
    let name: String
    let account: [Account]
    let accountCategory: [Category]
    let expenditure: [Account]
    let expenditureCategory: [Category]
    let revenue: [Account]
    let revenueCategory: [Category]

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case account
        case accountCategory = "account_category"
        case expenditure
        case expenditureCategory = "expenditure_category"
        case revenue
        case revenueCategory = "revenue_category"
    }
}

struct Account: Codable {
    let amount: String
    let date: Timestamp
//    let destinationAccountId: Category
//    let sourceAccountId: Category
    let accountId: Category
    let expenditureId: Category
//    let revenueId: Category
    let detail: String

    enum CodingKeys: String, CodingKey {
        case amount
        case date
//        case destinationAccountId = "destination_account_id"
//        case sourceAccountId = "source_account_id"
        case accountId = "account_id"
        case expenditureId = "expenditure_id"
//        case revenueId = "revenue_id"
        case detail
    }
}

struct Category: Codable {
    @DocumentID var documentID: String?
    let id: String?
    let title: String
}
