//
//  BBCoFireBaseManager.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/12/10.
//

import Foundation
import FirebaseFirestore

class BBCoFireBaseManager {
    static let shared = BBCoFireBaseManager()

    // MARK: - 上傳資料到Firebase
    func createUserData(id: String, subCollection: String, amount: String, category: String, account: String, date: String, month: String, detail: String, categoryImage: String, segment: Int) {
        let dataBase = Firestore.firestore()
        let documentRef = dataBase.collection("user")
            .document(id)
            .collection(subCollection)
            .document()
        // 讓swift code先去生成一組id並存起來，後續要識別document修改資料用
        let identifier = documentRef.documentID
        // 需存id，後續delete要抓取ID刪除對應資料
        switch subCollection {
        case "expenditure":
            let account = Account(
                id: identifier,
                amount: amount,
                category: category,
                account: account,
                date: date,
                month: month,
                destinationAccountId: nil,
                sourceAccountId: nil,
                accountId: "accountId",
                expenditureId: "expenditureId",
                revenueId: nil,
                detail: detail,
                categoryImage: categoryImage,
                segmentTag: segment)
            do {
                try documentRef.setData(from: account)
                print("success create document. ID: \(documentRef.documentID)")
            } catch {
                print(error)
            }
        case "revenue":
            let account = Account(
                id: identifier,
                amount: amount,
                category: category,
                account: account,
                date: date,
                month: month,
                destinationAccountId: nil,
                sourceAccountId: nil,
                accountId: "accountId",
                expenditureId: nil,
                revenueId: "revenueId",
                detail: detail,
                categoryImage: categoryImage,
                segmentTag: segment)
            do {
                try documentRef.setData(from: account)
                print("success create document. ID: \(documentRef.documentID)")
            } catch {
                print(error)
            }
        default:
            let account = Account(
                id: identifier,
                amount: amount,
                category: category,
                account: account,
                date: date,
                month: month,
                destinationAccountId: "destinationAccountId",
                sourceAccountId: "sourceAccountId",
                accountId: nil,
                expenditureId: nil,
                revenueId: nil,
                detail: detail,
                categoryImage: categoryImage,
                segmentTag: segment)
            do {
                try documentRef.setData(from: account)
                print("success create document. ID: \(documentRef.documentID)")
            } catch {
                print(error)
            }
        }
    }

    // MARK: - addNewDataVC待處理fetch category data
    // 從Firebase上fetch全部種類/帳戶資料
    func fetchUserCategory(id: String, subCollection: String) -> [String] {
        var contentArray: [String] = []
        let group = DispatchGroup()
        let dataBase = Firestore.firestore()
        group.enter()
        dataBase.collection("user/\(id)/\(subCollection)_category")
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let category = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Category.self)
                }
                
                for num in 0..<category.count {
                    contentArray.append(category[num].title)
                }
                group.leave()
            }
        group.notify(queue: .main) {
            print("=== contentArrayFromManager", contentArray)
        }
        return contentArray
    }
    
    
    
    // MARK: - EditVC
    // edit user data
    func editUserData(tableView: UITableView, id: String, subCollection: String, amount: String, category: String, account: String, month: String, detail: String, categoryImage: String, segment: Int) {
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? EditTimeTableViewCell
        else {
            fatalError("can not find AddDateTableViewCell")
        }
        let dataBase = Firestore.firestore()
        let fetchDocumentID = dataBase.collection("user")
            .document(id)
            .collection(subCollection)
            .document()
        // 讓swift code先去生成一組id並存起來，後續要識別document修改資料用
        let identifier = fetchDocumentID.documentID
        // 需存id，後續delete要抓取ID刪除對應資料
        switch subCollection {
        case "expenditure":
            let account = Account(
                id: identifier,
                amount: amount,
                category: category,
                account: account,
                date: BBCDateFormatter.shareFormatter.string(from: cell.editDatePicker.date),
                month: month,
                destinationAccountId: nil,
                sourceAccountId: nil,
                accountId: "accountId",
                expenditureId: "expenditureId",
                revenueId: nil,
                detail: detail,
                categoryImage: categoryImage,
                segmentTag: segment)
            do {
                try fetchDocumentID.setData(from: account)
                print("success create document. ID: \(fetchDocumentID.documentID)")
            } catch {
                print(error)
            }
        case "revenue":
            let account = Account(
                id: identifier,
                amount: amount,
                category: category,
                account: account,
                date: BBCDateFormatter.shareFormatter.string(from: cell.editDatePicker.date),
                month: month,
                destinationAccountId: nil,
                sourceAccountId: nil,
                accountId: "accountId",
                expenditureId: nil,
                revenueId: "revenueId",
                detail: detail,
                categoryImage: categoryImage,
                segmentTag: segment)
            do {
                try fetchDocumentID.setData(from: account)
                print("success create document. ID: \(fetchDocumentID.documentID)")
            } catch {
                print(error)
            }
        default:
            let account = Account(
                id: identifier,
                amount: amount,
                category: category,
                account: account,
                date: BBCDateFormatter.shareFormatter.string(from: cell.editDatePicker.date),
                month: month,
                destinationAccountId: "destinationAccountId",
                sourceAccountId: "sourceAccountId",
                accountId: nil,
                expenditureId: nil,
                revenueId: nil,
                detail: detail,
                categoryImage: categoryImage,
                segmentTag: segment)
            do {
                try fetchDocumentID.setData(from: account)
                print("success create document. ID: \(fetchDocumentID.documentID)")
            } catch {
                print(error)
            }
        }
    }
    
    // 點選對應細項編輯資料
    func editUserDetail(tableView: UITableView, id: String, subCollection: String, documentID: String, amount: String, category: String, account: String, detail: String, category_image: String) {
        let group = DispatchGroup()
        // 把indexPath(0, 0)的位置指向CoTimeTableViewCell，去cell裡面拿東西（非生成cell實例）
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? EditTimeTableViewCell
        else {
            fatalError("can not find AddDateTableViewCell")
        }
        let dataBase = Firestore.firestore()
        // 因為有API抓取時間差GCD問題，故用group/notice來讓API資料全部回來後再同步更新到tableView上
        // 進入group
        group.enter()
        dataBase.collection("user/\(id)/\(subCollection)").document("\(documentID)").updateData([
            // 按下編輯按鈕時塞值
            "date": BBCDateFormatter.shareFormatter.string(from: cell.editDatePicker.date),
            "amount": amount,
            "category": category,
            "account": account,
            "detail": detail,
            "category_image": category_image
        ]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document update successfully")
            }
            // 每一支API打完之後leave group
            group.leave()
        }
    }

    // 從firebase上刪除資料，delete firebase data需要一層一層找，不能用路徑
    func deleteSpecificData(id: String, subCollection: String, dataId: String) {
        let dataBase = Firestore.firestore()
        let documentRef = dataBase.collection("user").document(id).collection(subCollection).document(dataId)
        documentRef.delete()
    }
}
