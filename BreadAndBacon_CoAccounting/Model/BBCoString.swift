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
    // CoDetailVC
    let coDetailCellID = "coDetailCell"
    let coTimeCellID = "coTimeCell"
    // CoAccountVC
    let listCellID = "listCell"
    let addCoDetailVCID = "addCoDetailVC"
    // CoBookVC
    let coBookCellID = "coBookCell"
    let coAccountingVCID = "coAccountingVC"
    
}

struct HeaderTitle {
    let chooseDate = "選擇日期"
    let chooseCategory = "選擇細項"
    let chooseQRCode = "使用QRCode掃描發票"
    let chooseDetail = "備註"
    let expenditureDetail = "支出明細"
    let myAccountingBook = "我的帳本"
}

struct ErrorMessage {
    let fatalErrorMSG = "can not create cell"
    let fatalErrorMSGSpecific = "can not specific cell"
    let fatalErrorMSGQRVC = "can not find QRScanner VC"
    let fatalErrorMSGEditQRVC = "can not find EditQRScanner VC"
    let fatalErrorMSGCoDetailVC = "can not find CoDetailVC"
    let fatalErrorMSGCoAccountingVC = "can not push coAccountingVC"
    let fatalErrorMSGCoBookTableViewCell = "can not find CoBookTableViewCell"
}

struct ImageName {
    
}
