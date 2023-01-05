//
//  BBCoFireBaseManager.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/12/10.
//  swiftlint:disable line_length
//  swiftlint:disable type_body_length
//  swiftlint: disable function_parameter_count

import Foundation
import FirebaseFirestore
import CoreMedia

enum Result<Success, Failure> where Failure: Error {
    case success(Success)
    case failure(Failure)
}

class BBCoFireBaseManager {
    static let shared = BBCoFireBaseManager()
    private init(){}
    let dataBase = Firestore.firestore()

    // addNewDataVC
    func createUserData(id: String, subCollection: String, amount: String, category: String, account: String, date: String, month: String, detail: String, categoryImage: String, segment: Int) {
        let documentRef = dataBase.collection("user")
            .document(id)
            .collection(subCollection)
            .document()
        let identifier = documentRef.documentID
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

    func fetchUserCategory(id: String, subCollection: String, completion: @escaping([String]) -> Void) {
        var contentArray: [String] = []
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
                completion(contentArray)
            }
    }

    // categoryVC
    func fetchSideMenuCategory(id: String, subCollection: String, completion: @escaping(([Category]) -> Void)) {
        var categoryData: [Category] = []
        dataBase.collection("user/\(id)/\(subCollection)_category")
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let category = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Category.self)
                }
                categoryData.append(contentsOf: category)
                completion(categoryData)
            }
    }

    func deleteSideMenuCategory(id: String, subCollection: String, indexPathRow: Int, dataId: String) {
        let documentRef = dataBase
            .collection("user")
            .document(id)
            .collection("\(subCollection)_category")
            .document(dataId)
        documentRef.delete()
    }

    // EditVC
    func editUserData(tableView: UITableView, id: String, subCollection: String, date: String, amount: String, category: String, account: String, month: String, detail: String, categoryImage: String, segment: Int) {
        let fetchDocumentID = dataBase.collection("user")
            .document(id)
            .collection(subCollection)
            .document()
        let identifier = fetchDocumentID.documentID
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
                try fetchDocumentID.setData(from: account)
                print("success create document. ID: \(fetchDocumentID.documentID)")
            } catch {
                print(error)
            }
        }
    }

    func editUserDetail(tableView: UITableView, id: String, subCollection: String, documentID: String, date: String, amount: String, category: String, account: String, detail: String, categoryImage: String) {
        dataBase.collection("user/\(id)/\(subCollection)").document("\(documentID)").updateData([
            "date": date,
            "amount": amount,
            "category": category,
            "account": account,
            "detail": detail,
            "category_image": categoryImage
        ]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document update successfully")
            }
        }
    }

    func deleteSpecificData(id: String, subCollection: String, dataId: String) {
        let documentRef = dataBase.collection("user").document(id).collection(subCollection).document(dataId)
        documentRef.delete()
    }

    // pieChartVC
    func fetchMonthOverview(id: String, subCollection: String, monthData: Date, completion: @escaping([Account]) -> Void) {
        var userData: [Account] = []
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月"
        dataBase.collection("user/\(id)/\(subCollection)")
            .whereField("month", isEqualTo: BBCDateFormatter.shareFormatter.string(from: monthData))
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let account = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Account.self)
                }
                userData.append(contentsOf: account)
                completion(userData)
            }
    }

    // homeVC
    func fetchUserSpecific(id: String, subCollection: String, date: Date, completion: @escaping([Account]) -> Void) {
        var dailyData: [Account] = []
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
        dataBase.collection("user/\(id)/\(subCollection)")
            .whereField("date", isEqualTo: BBCDateFormatter.shareFormatter.string(from: date))
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let account = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Account.self)
                }
                dailyData.append(contentsOf: account)
                completion(dailyData)
            }
    }


    // CoBookVC
    func createCoAccountBookData(bookNameString: String, userIdArray: [String]) -> String {
        let documentID = dataBase.collection("co-account").document()
        let identifier = documentID.documentID
        let prefixID = identifier.prefix(5)
        let book = Book(id: identifier, roomId: String(prefixID), name: bookNameString, userId: userIdArray)
        do {
            try documentID.setData(from: book)
            print("success create document. ID: \(documentID.documentID)")
        } catch {
            print(error)
        }

        return identifier
    }

    func editSpecificData(bookData: [Book], indexPathRow: Int, textField: String) {
        dataBase.collection("co-account").document(bookData[indexPathRow].id).updateData(["name": textField]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document update successfully")
            }
        }
    }

    func deleteSpecificData(bookData: [Book], indexPathRow: Int) {
        let documentRef = dataBase.collection("co-account").document(bookData[indexPathRow].id)
        documentRef.delete()
    }

    func deleteSpecificSubcollection(bookData: [Book], indexPathRow: Int, bookDetailData: [Account], documentNum: Int) {
        let documentRef = dataBase.collection("co-account").document(bookData[indexPathRow].id).collection("co_expenditure").document(bookDetailData[documentNum].id)
        documentRef.delete()
    }

    func fetchBookSpecific(collection: String, field: String, inputID: String, completion: @escaping([Book]) -> Void) {
        var specificBook: [Book] = []
        dataBase.collection(collection)
            .whereField(field, isEqualTo: inputID)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let snapshot = snapshot else {
                    return
                }
                let book = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Book.self)
                }
                specificBook.append(contentsOf: book)
                completion(specificBook)
            }
    }

    func updateUserToBook(bookIdentifier: String, userId: String, userContentData: [User], userNameData: [String], completion: (() -> Void)? = nil) {
        var userContentArray: [User] = []
        var userNameArray: [String] = []
        let group = DispatchGroup()
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
                group.leave()
            }

        group.notify(queue: .main) {
            self.dataBase.collection("co-account")
                .document(bookIdentifier)
                .updateData(["user_id": FieldValue.arrayUnion(userNameArray)]) { error in
                if let error = error {
                    print("Error updating document: \(error)")
                } else {
                    print("Document update successfully in ID: \(userNameArray)")
                    completion?()
                }
            }
        }
    }

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
                completion(bookData)
            }
    }

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

    // CoAccountingVC
    func fetchCoBookDetail(document: String, subCollection: String, completion: @escaping(([Account]) -> Void)) {
        var coBookDetailData: [Account] = []
        dataBase.collection("co-account/\(document)/\(subCollection)")
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let account = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Account.self)
                }
                coBookDetailData.append(contentsOf: account)
                print("book datail here \(coBookDetailData)")
                completion(coBookDetailData)
            }
    }

    func deleteSpecificData(accountData: [Account], document: String, subCollection: String, indexPathRow: Int) {
        let documentRef = dataBase.collection("co-account").document(document).collection(subCollection).document(accountData[indexPathRow].id)
        documentRef.delete()
    }

    // addCoDetailVC
    func createCoAccountData(tableView: UITableView, document: String, subCollection: String, amount: String, category: String, month: String, user: String) {
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? CoTimeTableViewCell
        else {
            fatalError("can not find CoTimeTableViewCell")
        }
        let documentID = dataBase.collection("co-account")
            .document(document)
            .collection(subCollection)
            .document()
        let identifier = documentID.documentID
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

    func fetchMember(didSelecetedBook: String, completion: @escaping(([String]) -> Void)) {
        var userContentData: [String] = []
        let docRef = dataBase.collection("co-account").document(didSelecetedBook)

        docRef.getDocument { (document, error) in
            if let document = document, document.exists,
               let data = try? document.data(as: Book.self)
            {
                userContentData.append(contentsOf: data.userId)
                completion(userContentData)
            } else {
                print("Document does not exist")
            }
        }
    }

    func editUser(tableView: UITableView, document: String, subCollection: String, documentID: String, date: String, amount: String, category: String, user: String) {
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? CoTimeTableViewCell else {
            fatalError("can not find CoTimeTableViewCell")
        }
        dataBase.collection("co-account/\(document)/\(subCollection)").document("\(documentID)").updateData([
            "date": date,
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

    // signInVC
    func createUserIdentify(id: String, email: String, name: String) {
        let userID = dataBase.collection("user")
        let identifier = userID.document(id)
        let collection = User(id: id, email: email, name: name)

        do {
            try identifier.setData(from: collection)
            print("success create user document ID: \(identifier)")
        } catch {
            print(error)
        }
    }

    func createCategory(id: String, subCollection: String, content: String) {
        let documentRef = dataBase.collection("user").document(id).collection(subCollection).document()
        let collection = Category(id: documentRef.documentID, title: content)

        do {
            try documentRef.setData(from: collection)
        } catch {
            print(error)
        }
    }

    // MenuListTableVC
    func deleteUser(userId: String) {
        let documentRef = dataBase.collection("user").document(userId)
        documentRef.delete()
    }

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
                    completion(.success(bookContentData))
                }
            }
    }

    func deleteCoBook(bookId: String, completion: (() -> Void)? = nil) {
        dataBase.collection("co-account").document(bookId).delete()
        completion?()
    }

    func deleteUserFromCoBook(bookId: String, userName: String, completion: (() -> Void)? = nil) {
        dataBase.collection("co-account")
            .document(bookId)
            .updateData(["user_id": FieldValue.arrayRemove([userName])])
        completion?()
    }
}
