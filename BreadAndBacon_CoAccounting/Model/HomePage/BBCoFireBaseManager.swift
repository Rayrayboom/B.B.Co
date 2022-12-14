//
//  BBCoFireBaseManager.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/12/10.
//

import Foundation
import FirebaseFirestore
import CoreMedia

class BBCoFireBaseManager {
    static let shared = BBCoFireBaseManager()
    let dataBase = Firestore.firestore()

    // MARK: - 上傳資料到Firebase
    func createUserData(id: String, subCollection: String, amount: String, category: String, account: String, date: String, month: String, detail: String, categoryImage: String, segment: Int) {
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
    func createCoAccountBookData(bookNameString: String, userIdArray: [String]) -> String {
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
        let documentRef = dataBase.collection("co-account").document(bookData[indexPathRow].id)
        documentRef.delete()
    }
    
    // 從firebase上刪除document底下的subCollection，delete firebase data需要一層一層找，不能用路徑
    func deleteSpecificSubcollection(bookData: [Book], indexPathRow: Int, bookDetailData: [Account], documentNum: Int) {
        let documentRef = dataBase.collection("co-account").document(bookData[indexPathRow].id).collection("co_expenditure").document(bookDetailData[documentNum].id)
        documentRef.delete()
    }

    // 更新付款人到對應帳本
    func updateUserToBook(bookIdentifier: String, userId: String, userContentData: [User], userNameData: [String], completion: (() -> Void)? = nil) {
        var userContentArray: [User] = []
        var userNameArray: [String] = []
        let group = DispatchGroup()
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
            self.dataBase.collection("co-account")
                .document(bookIdentifier)
                .updateData(["user_id": FieldValue.arrayUnion(userNameArray)]) { error in
                if let error = error {
                    print("Error updating document: \(error)")
                } else {
                    print("Document update successfully in ID: \(userNameArray)")
                    // 啟動completion
                    completion?()
                }
            }
        }
    }

    // fetch所有包含自己的共同帳本
    func fetchCoBook(userName: String, completion: @escaping([Book]) -> Void) {
        var bookData: [Book] = []
        dataBase.collection("co-account").whereField("user_id", arrayContains: userName)
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let book = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Book.self)
                }
                bookData.append(contentsOf: book)
                // 啟動completion才會執行傳值
                completion(bookData)
            }
    }

    // 從Firebase上fetch對應book的detail資料
    func fetchBookDetail(document: String, subCollection: String, completion: @escaping([Account]) -> Void) {
        var bookDetailData: [Account] = []
        dataBase.collection("co-account/\(document)/\(subCollection)")
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let account = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Account.self)
                }
                bookDetailData.append(contentsOf: account)
                completion(bookDetailData)
            }
    }

    // MARK: - CoAccountingVC
    // 從firebase上刪除資料，delete firebase data需要一層一層找，不能用路徑
    func deleteSpecificData(accountData: [Account], document: String, subCollection: String, indexPathRow: Int) {
        let documentRef = dataBase.collection("co-account").document(document).collection(subCollection).document(accountData[indexPathRow].id)
        documentRef.delete()
    }

    // MARK: - addCoDetailVC
    // 上傳資料到Firebase
    func createCoAccountData(tableView: UITableView, document: String, subCollection: String, amount: String, category: String, month: String, user: String) {
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? CoTimeTableViewCell
        else {
            fatalError("can not find CoTimeTableViewCell")
        }
        let documentID = dataBase.collection("co-account")
            .document(document)
            .collection(subCollection)
            .document()
        // 讓swift code先去生成一組id並存起來，後續要識別document修改資料用
        let identifier = documentID.documentID
        // 需存id，後續delete要抓取ID刪除對應資料
        let account = Account(
            id: identifier,
            amount: amount,
            category: category,
            account: nil,
            date: BBCDateFormatter.shareFormatter.string(from: cell.datePicker.date), //data.dateTime,
            month: month,
            destinationAccountId: nil,
            sourceAccountId: nil,
            accountId: nil,
            expenditureId: "expenditureId",
            revenueId: nil,
            detail: nil,
            user: user,
            categoryImage: nil,
            segmentTag: nil)
        do {
            try documentID.setData(from: account)
            print("success create document. ID: \(documentID.documentID)")
        } catch {
            print(error)
        }
    }

    // 點選對應細項編輯資料
    func editUser(tableView: UITableView, document: String, subCollection: String, documentID: String, date: String, amount: String, category: String, user: String) {
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
        // 把indexPath(0, 0)的位置指向CoTimeTableViewCell，去cell裡面拿東西（非生成cell實例）
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? CoTimeTableViewCell else {
            fatalError("can not find CoTimeTableViewCell")
        }
        dataBase.collection("co-account/\(document)/\(subCollection)").document("\(documentID)").updateData([
            // 這邊兩種方法都可以，因為data.dateTime也透過cell的delegate塞了cell的date資料了，(針對date讓一開始顯示畫面時就先吃到datePicker的資料，不用等到點選變更後才塞資料)
            "date": date,
            //BBCDateFormatter.shareFormatter.string(from: cell.datePicker.date),
            "amount": amount,
            "category": category,
            "user": user
        ]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document update successfully ")
            }
        }
    }

    // MARK: - signInVC
    // 建立使用者資料，document id設為user id(因為user id一人對應一組不會變)
    func createUserIdentify(id: String, email: String, name: String) {
        // 建立firebase路徑
        let userID = dataBase.collection("user")
        // 於路徑中新增一筆document，document id為user id
        let identifier = userID.document(id)
        let collection = User(id: id, email: email, name: name)

        do {
            try identifier.setData(from: collection)
            print("success create user document ID: \(identifier)")
        } catch {
            print(error)
        }
    }

    // 新增對應category細項
    func createCategory(id: String, subCollection: String, content: String) {
        let db = Firestore.firestore()
        let documentRef = db.collection("user").document(id).collection(subCollection).document()
        let collection = Category(id: documentRef.documentID, title: content)

        do {
            try documentRef.setData(from: collection)
        } catch {
            print(error)
        }
    }
    
    // MARK: - MenuListTableVC
    // 個人（個人資訊+個人記帳細項）
    // 從firebase上刪除資料，delete firebase data需要一層一層找，不能用路徑
    func deleteUser(userId: String) {
        let documentRef = dataBase.collection("user").document(userId)
        documentRef.delete()
    }

    // 刪除個人記帳單一subCollection底下所有的資料
    func deleteSubCollectionDoc(userId: String, subCollection: String) {
        let documentRef = dataBase.collection("user").document(userId).collection(subCollection)
        documentRef.getDocuments { querySnapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                guard let querySnapshot = querySnapshot else {
                    return
                }
                for document in querySnapshot.documents {
                    print("=== this is documentID \(document.documentID)")
                    document.reference.delete()
                }
            }
        }
    }

    // MARK: - 刪除共同（共同帳本付款者）
    // Result type
    enum Result<Success, Failure> where Failure: Error {
        case success(Success)
        case failure(Failure)
    }

    // 先搜尋co-account裡有哪些book包含getName(付款人-userName)
    func fetchUserAllCoBook(userName: String, completion: @escaping /*([Book]) -> Void*/ (Result<[Book], Error>) -> Void) {
        var bookContentData: [Book] = []
        dataBase.collection("co-account").whereField("user_id", arrayContains: userName)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    guard let snapshot = snapshot else {
                        return
                    }
                    let book = snapshot.documents.compactMap { snapshot in
                        try? snapshot.data(as: Book.self)
                    }
                    bookContentData.append(contentsOf: book)
                    print("=== is bookContent", bookContentData)
                    completion(.success(bookContentData))
                }
            }
    }

    // 把有包含我的book用forEach一個一個找，如果user_id == 1表示我刪除帳號後這本帳本也就失效，因此連同帳本一併刪除，因為VC的group.leave需要在completion後實現，但因以下兩個func沒有要回傳值，故用optional的completion
    func deleteCoBook(bookId: String, completion: (() -> Void)? = nil) {
        dataBase.collection("co-account").document(bookId).delete()
        completion?()
    }

    // 若user_id超過一人，表示還有其他使用者在這本帳本裡，因此只執行把我自己從付款者裡移除
    func deleteUserFromCoBook(bookId: String, userName: String, completion: (() -> Void)? = nil) {
        dataBase.collection("co-account")
            .document(bookId)
            .updateData(["user_id": FieldValue.arrayRemove([userName])])
        completion?()
    }
}

