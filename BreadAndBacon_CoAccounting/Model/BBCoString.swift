//
//  BBCoString.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2023/1/28.
//

import Foundation

struct SubCategory {
    let expenditure = "expenditure"
    let revenue = "revenue"
    let account = "account"
    let coExpenditure = "co_expenditure"
}

struct Identifier {
    // AddDataVC
    let addDataDateCellID = "dateCell"
    let addDataDataCellID = "addDataCell"
    let addDataQRCellID = "QRCell"
    let addDataDetailCellID = "detailCell"
    let addDataQRScanVCID = "qrScanVC"
    // EditDataVC
    let editTimeCellID = "editTimeCell"
    let editDataCellID = "editDataCell"
    let editQRCellID = "editQRCell"
    let editDetailCellID = "editDetailCell"
    let editQRScanVCID = "editQRScanVC"
}

struct HeaderTitle {
    let chooseDate = "選擇日期"
    let chooseCategory = "選擇細項"
    let chooseQRCode = "使用QRCode掃描發票"
    let chooseDetail = "備註"
}

struct ErrorMessage {
    let fatalErrorMSG = "can not create cell"
    let fatalErrorMSGSpecific = "can not specific cell"
    let fatalErrorMSGQRVC = "can not find QRScanner VC"
    let fatalErrorMSGEditQRVC = "can not find EditQRScanner VC"
}
