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
    var id: String
    var amount: String
    var category: String
    var account: String
    // date改用string型別存取，因為只需要存"年/月/日"，存時間"時/分"的話後續無法抓取資料
    var date: String
    // month用string型別存取"年/月"，讓pie chart直接偵測該月份抓整月資訊
    var month: String
    var destinationAccountId: String? // = nil
    var sourceAccountId: String? // = nil
    var accountId: String? // = nil
    var expenditureId: String? // = nil
    var revenueId: String? // = nil
    var detail: String

    enum CodingKeys: String, CodingKey {
        case id
        case amount
        case category
        case account
        case date
        case month
        case destinationAccountId = "destination_account_id"
        case sourceAccountId = "source_account_id"
        case accountId = "account_id"
        case expenditureId = "expenditure_id"
        case revenueId = "revenue_id"
        case detail
    }
}

struct Category: Codable {
    @DocumentID var documentID: String?
    let id: String?
    let title: String
}
