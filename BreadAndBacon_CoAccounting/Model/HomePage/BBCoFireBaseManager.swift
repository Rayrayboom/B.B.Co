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
        let documentRef = dataBase.collection("user").document(id).collection(subCollection).document(dataId ?? "")
        documentRef.delete()
    }

    // MARK: - homeVC
    // MARK: - homeVC待處理fetch category data
    // 從Firebase上抓當前選擇日期的資料，並fetch資料下來
    func fetchUserSpecific(id: String, subCollection: String) -> [Account] {
        let group = DispatchGroup()
        let date = Date()
        var data: [Account] = []
        // fetch firebase指定條件為date的資料時，用"yyyy 年 MM 月 dd 日"格式來偵測
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
        let dataBase = Firestore.firestore()
        // 因為有API抓取時間差GCD問題，故用group/notice來讓API資料全部回來後再同步更新到tableView上
        // 進入group
        group.enter()
        // 因為UIDatePicker一定要在main thread做，但group是在global執行，因此先在全域宣告一個Date型別的變數，當fetch data抓date picker的日期資料時，改用全域變數的date拿到date的資料(self.date)
        dataBase.collection("user/\(id)/\(subCollection)")
            .whereField("date", isEqualTo: BBCDateFormatter.shareFormatter.string(from: date))
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let account = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Account.self)
                }
                data.append(contentsOf: account)
                // 每一支API打完之後leave group
                group.leave()
            }
        return data
    }


    // MARK: - CoBookVC
    // 上傳 book id & user_id 到Firebase
    func createCoAccountData(bookNameString: String, userIdArray: [String]) -> String {
        let dataBase = Firestore.firestore()
        let documentID = dataBase.collection("co-account").document()
        // 讓swift code先去生成一組id並存起來，後續要識別document修改資料用
        let identifier = documentID.documentID
        let prefixID = identifier.prefix(5)
        // 需存id，後續delete要抓取ID刪除對應資料
        let book = Book(id: identifier, roomId: String(prefixID), name: bookNameString, userId: userIdArray)
        do {
            try documentID.setData(from: book)
            print("success create document. ID: \(documentID.documentID)")
        } catch {
            print(error)
        }
        
        return identifier
    }

    // 重新編輯對應的book name
    func editSpecificData(bookData: [Book], indexPathRow: Int, textField: String) {
        let dataBase = Firestore.firestore()
        dataBase.collection("co-account").document(bookData[indexPathRow].id).updateData(["name": textField]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document update successfully")
            }
        }
    }

    // 從firebase上刪除指定document，delete firebase data需要一層一層找，不能用路徑
    func deleteSpecificData(bookData: [Book], indexPathRow: Int) {
        let dataBase = Firestore.firestore()
        let documentRef = dataBase.collection("co-account").document(bookData[indexPathRow].id)
        documentRef.delete()
    }
    
    // 從firebase上刪除document底下的subCollection，delete firebase data需要一層一層找，不能用路徑
    func deleteSpecificSubcollection(bookData: [Book], indexPathRow: Int, bookDetailData: [Account], documentNum: Int) {
        let dataBase = Firestore.firestore()
        let documentRef = dataBase.collection("co-account").document(bookData[indexPathRow].id).collection("co_expenditure").document(bookDetailData[documentNum].id)
        documentRef.delete()
    }

    // 更新付款人到對應帳本
    func updateUserToBook(bookIdentifier: String, userId: String, userContentData: [User], userNameData: [String]) {
//        userContent = []
//        userName = []
        var userContentArray: [User] = []
        var userNameArray: [String] = []
        let group = DispatchGroup()
        let dataBase = Firestore.firestore()
        // 因為有API抓取時間差GCD問題，故用group/notice來讓API資料全部回來後再update user_is data
        // 進入group
        group.enter()
        dataBase.collection("user")
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let user = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: User.self)
                }

                userContentArray.append(contentsOf: user)
                userContentArray.forEach { item in
                    if item.id == userId {
                        userNameArray.append(item.name ?? "")
                    }
                }
                // API打完回來之後leave group
                group.leave()
            }

        // 等API執行完後notify它去updateData(用arrayUnion)
        group.notify(queue: .main) {
            dataBase.collection("co-account")
                .document(bookIdentifier)
                .updateData(["user_id": FieldValue.arrayUnion(userNameArray)]) { error in
                if let error = error {
                    print("Error updating document: \(error)")
                } else {
                    print("Document update successfully in ID: \(userNameArray)")
                    // 等完全新增完付款者後，再去fetach一次book的資料看哪幾本有自己並顯示
//                    self.fetchCoBook()
                }
            }
        }
    }
    
    // MARK: - coBookVC待處理fetch category data
    func fetchCoBook(userName: String) -> [Book] {
//        data = []
        var bookData: [Book] = []
        let group = DispatchGroup()
        let dataBase = Firestore.firestore()
        group.enter()
        dataBase.collection("co-account").whereField("user_id", arrayContains: userName)
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let book = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Book.self)
                }
                bookData.append(contentsOf: book)
                print("=== book in fireBase \(bookData)")
                group.leave()
            }
        print("=== book after fireBase \(bookData)")
        return bookData
    }

    // MARK: - CoAccountingVC
    // 從firebase上刪除資料，delete firebase data需要一層一層找，不能用路徑
    func deleteSpecificData(accountData: [Account], document: String, subCollection: String, indexPathRow: Int) {
        let dataBase = Firestore.firestore()
        let documentRef = dataBase.collection("co-account").document(document).collection(subCollection).document(accountData[indexPathRow].id)
        documentRef.delete()
    }


}
