//
//  BBCoString.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2023/1/28.
//

import Foundation

enum Identifier {
    // AddDataVC
    static let addDataDateCellID = "dateCell"
    static let addDataDataCellID = "addDataCell"
    static let addDataQRCellID = "QRCell"
    static let addDataDetailCellID = "detailCell"
    static let addDataQRScanVCID = "qrScanVC"
    // EditDataVC
    static let editTimeCellID = "editTimeCell"
    static let editDataCellID = "editDataCell"
    static let editQRCellID = "editQRCell"
    static let editDetailCellID = "editDetailCell"
    static let editQRScanVCID = "editQRScanVC"
    // CoDetailVC
    static let coDetailCellID = "coDetailCell"
    static let coTimeCellID = "coTimeCell"
    // CoAccountVC
    static let listCellID = "listCell"
    static let addCoDetailVCID = "addCoDetailVC"
    // CoBookVC
    static let coBookCellID = "coBookCell"
    static let coAccountingVCID = "coAccountingVC"
    // CategoryVC
    static let categoryCellID = "categoryCell"
}

enum SubCategory {
    static let user = "user"
    static let expenditure = "expenditure"
    static let revenue = "revenue"
    static let account = "account"
    static let coAccount = "co-account"
    static let coExpenditure = "co_expenditure"
}

enum HeaderTitle {
    static let chooseDate = "選擇日期"
    static let chooseCategory = "選擇細項"
    static let chooseQRCode = "使用QRCode掃描發票"
    static let chooseDetail = "備註"
    static let expenditureDetail = "支出明細"
    static let myAccountingBook = "我的帳本"
    static let categoryList = "種類列表"
}

enum ErrorMessage {
    static let fatalErrorMSG = "can not create cell"
    static let fatalErrorMSGSpecific = "can not specific cell"
    static let fatalErrorMSGQRVC = "can not find QRScanner VC"
    static let fatalErrorMSGEditQRVC = "can not find EditQRScanner VC"
    static let fatalErrorMSGCoDetailVC = "can not find CoDetailVC"
    static let fatalErrorMSGCoAccountingVC = "can not push coAccountingVC"
    static let fatalErrorMSGCoBookTableViewCell = "can not find CoBookTableViewCell"
}

struct ImageName {
    
}
