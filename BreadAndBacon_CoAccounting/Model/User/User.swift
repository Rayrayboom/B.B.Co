//
//  User.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/2.
//

import Foundation
import FirebaseFirestoreSwift

struct User: Codable {
    @DocumentID var documentID: String?
    let id: String?
    let email: String?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
    }
}

struct Account: Codable {
    var id: String
    var amount: String
    var category: String?
    var account: String?
    // date改用string型別存取，因為只需要存"年/月/日"，存時間"時/分"的話後續無法抓取資料
    var date: String
    // month用string型別存取"年/月"，讓pie chart直接偵測該月份抓整月資訊
    var month: String
    var destinationAccountId: String?
    var sourceAccountId: String?
    var accountId: String?
    var expenditureId: String?
    var revenueId: String?
    var detail: String?
    var user: String?
    // 記個人記帳圖案資料
    var categoryImage: String?
    // 儲存單筆資料種類來源(expenditure(0), revenue(1), account(2))
    var segmentTag: Int?

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
        // 給co_accounting用的型別，因為要記錄是哪個使用者的支出
        case user
        // 記個人記帳圖案資料
        case categoryImage = "category_image"
        case segmentTag = "segment_tag"
    }
}

struct Category: Codable {
    @DocumentID var documentID: String?
    let id: String?
    let title: String
}

struct Book: Codable {
    let id: String
    let roomId: String
    let name: String
    let userId: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case roomId = "room_id"
        case name
        case userId = "user_id"
    }
}

struct Invoice: Codable {
    let msg, code, invNum, invoiceTime: String
    let invStatus, sellerName, invPeriod, sellerAddress: String
    let sellerBan, buyerBan, currency: String
    let details: [InvDetail]
    let invDate: String
}

struct InvDetail: Codable {
    let unitPrice, amount, quantity, rowNum: String
    let detailDescription: String

    enum CodingKeys: String, CodingKey {
        case unitPrice, amount, quantity, rowNum
        case detailDescription = "description"
    }
}

struct RefreshToken: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String
    let idToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
    }
}
