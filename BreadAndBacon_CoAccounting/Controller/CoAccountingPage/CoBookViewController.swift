//
//  CoBookViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/11.
//

import UIKit
import FirebaseFirestore
import SwiftKeychainWrapper

class CoBookViewController: UIViewController {
    var data: [Book] = [] {
        didSet {
            bookTableView.reloadData()
        }
    }
    var bookDetail: [Account] = []

    // 用來存現有的user
    var userContent: [User] = []
    // 用來存user name
    var userName: [String] = []
    // 宣告一個alertVC
    var controller = UIAlertController()
    var bookName: String = ""
    var inputBookID: String = ""
    var specificBook: [Book] = []
    // 存keychain user id
    var getId: String = ""
    // 存keychain user name
    var getName: String = ""
    let group = DispatchGroup()
    // 新增co_account book時儲存自動生成的document id
    var identifier: String = ""

    @IBOutlet weak var bookTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        getId = KeychainWrapper.standard.string(forKey: "id") ?? ""
        getName = KeychainWrapper.standard.string(forKey: "name") ?? ""
        bookTableView.delegate = self
        bookTableView.dataSource = self
        // 新增共同帳本func
        addNewCoAccountBook()
        // 加入共同帳本func
        joinCoAccountBook()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        fetchCoBook()
        bookTableView.reloadData()
        // 回到帳本目錄時時恢復下方tabbar
        self.tabBarController?.tabBar.isHidden = false
    }

    // 按下右上button讓使用者輸入book name並新增帳本
    func addNewCoAccountBook() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(saveEdit))
    }

    // 觸發新增帳本func
    @objc func saveEdit() {
        addCoAccountingBookAlert()
    }

    // 新增帳本的alert，讓使用者輸入帳本名稱
    func addCoAccountingBookAlert() {
        controller = UIAlertController(title: "新增帳本", message: "", preferredStyle: .alert)
        controller.addTextField { textField in
            textField.placeholder = "帳本名稱"
            textField.keyboardType = UIKeyboardType.default
        }
        // 按下OK執行新增account book(使用者輸入accounnt book name)
        let okAction = UIAlertAction(title: "OK", style: .default) { [unowned controller] _ in
            self.bookName = controller.textFields?[0].text ?? ""
            self.createCoAccountData()
            self.fetchCoBook()
            // 按下新增帳本時，在該帳本的付款人會先預設加上本人
            self.updateUserToBook(bookIdentifier: self.identifier)
        }
        controller.addAction(okAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        // 記得要present後alert才會出現
        present(controller, animated: true)
    }

    // 按下左上button讓使用者輸入帳本id來加入帳本
    func joinCoAccountBook() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "book"), style: .plain, target: self, action: #selector(checkRoomId))
    }

    // 觸發加入帳本func
    @objc func checkRoomId() {
        joinCoAccountingBookAlert()
    }

    // 加入帳本的alert，讓使用者輸入帳本id
    func joinCoAccountingBookAlert() {
        controller = UIAlertController(title: "Co-Account book ID", message: "請輸入帳本ID加入共同記帳", preferredStyle: .alert)
        controller.addTextField { textField in
            textField.placeholder = "Account book ID"
            textField.keyboardType = UIKeyboardType.default
        }
        // 按下OK執行新增account book(使用者輸入accounnt book name)
        let okAction = UIAlertAction(title: "OK", style: .default) { [unowned controller] _ in
            self.inputBookID = controller.textFields?[0].text ?? ""
            self.fetchBookSpecific(collection: "co-account", field: "room_id", inputID: self.inputBookID)
        }
        controller.addAction(okAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        // 記得要present後alert才會出現
        present(controller, animated: true)
    }

    func updateUserToBook(bookIdentifier: String) {
        userContent = []
        userName = []
        let dataBase = Firestore.firestore()
        // 因為有API抓取時間差GCD問題，故用group/notice來讓API資料全部回來後再update user_is data
        // 進入group
        self.group.enter()
        dataBase.collection("user")
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let user = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: User.self)
                }

                self.userContent.append(contentsOf: user)
                self.userContent.forEach { item in
                    if item.id == self.getId {
                        self.userName.append(item.name ?? "")
                    }
                }
                // API打完回來之後leave group
                self.group.leave()
            }

        // 等API執行完後notify它去updateData(用arrayUnion)
        group.notify(queue: .main) {
            dataBase.collection("co-account")
                .document(bookIdentifier)
                .updateData(["user_id": FieldValue.arrayUnion(self.userName)]) { error in
                if let error = error {
                    print("Error updating document: \(error)")
                } else {
                    print("Document update successfully in ID: \(self.userName)")
                    // 等完全新增完付款者後，再去fetach一次book的資料看哪幾本有自己並顯示
                    self.fetchCoBook()
                }
            }
        }
    }

    // 從Firebase上抓符合book id的document，並fetch資料下來
    func fetchBookSpecific(collection: String, field: String, inputID: String) {
        specificBook = []
        let dataBase = Firestore.firestore()
        dataBase.collection(collection)
            .whereField(field, isEqualTo: inputID)
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let book = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Book.self)
                }
                self.specificBook.append(contentsOf: book)
                self.updateUserToBook(bookIdentifier: self.specificBook[0].id)
                print("I find the document \(self.specificBook)")
            }
    }

    // 針對對應的帳本新增付款人資訊
//    func createBookSpecific(bookIdentifier: String) {
//        let dataBase = Firestore.firestore()
//        print("useruser", self.userName)
//        dataBase.collection("co-account").document(bookIdentifier)
//            .updateData(["user_id": FieldValue.arrayUnion(userName)]) { error in
//            if let error = error {
//                print("Error updating document: \(error)")
//            } else {
//                print("Document update successfully in ID: \(self.userName)")
//            }
//        }
//    }

    // MARK: - 上傳 book id & user_id 到Firebase
    func createCoAccountData() {
        let dataBase = Firestore.firestore()
        let documentID = dataBase.collection("co-account").document()
        // 讓swift code先去生成一組id並存起來，後續要識別document修改資料用
        identifier = documentID.documentID
        let prefixID = identifier.prefix(5)
        // 需存id，後續delete要抓取ID刪除對應資料
        let book = Book(id: identifier, roomId: String(prefixID), name: bookName, userId: userName)
        do {
            try documentID.setData(from: book)
            print("success create document. ID: \(documentID.documentID)")
        } catch {
            print(error)
        }
    }

    // 從Firebase上fetch全部user資料，判斷目前使用者的id後取得name並append到userId array裡
//    func fetchUser() {
//        userName = []
//        let dataBase = Firestore.firestore()
//        dataBase.collection("user")
//            .getDocuments { snapshot, error in
//                guard let snapshot = snapshot else {
//                    return
//                }
//                let user = snapshot.documents.compactMap { snapshot in
//                    try? snapshot.data(as: User.self)
//                }
//
//                self.userContent.append(contentsOf: user)
//                self.userContent.forEach { item in
//                    if item.id == self.getId {
//                        self.userName.append(item.name ?? "")
//                    }
//                }
//                print("userContent", self.userContent)
//                print("userName", self.userName)
//            }
//    }

    // 從Firebase上fetch有幾本帳本user id是有我自己的(因為user_id是array，因此要用whereField-arrayContains來判斷array裡的元素)
    func fetchCoBook() {
        data = []
        let dataBase = Firestore.firestore()
        dataBase.collection("co-account").whereField("user_id", arrayContains: getName)
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let book = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Book.self)
                }
                self.data.append(contentsOf: book)
                print("book here \(self.data)")
            }
    }

    // 從firebase上刪除資料，delete firebase data需要一層一層找，不能用路徑
    func deleteSpecificData(indexPathRow: Int) {
        let dataBase = Firestore.firestore()
        let documentRef = dataBase.collection("co-account").document(data[indexPathRow].id)
        documentRef.delete()
    }
}

// 點下帳本會導到對應帳目資訊
extension CoBookViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let pushCoAccountingVC = self.storyboard?.instantiateViewController(withIdentifier: "coAccountingVC")as? CoAccountingViewController
        else {
            fatalError("can not push coAccountingVC")
        }
        pushCoAccountingVC.didSelecetedBook = data[indexPath.row].id
        print("datadatddtd", data)

        navigationController?.pushViewController(pushCoAccountingVC, animated: true)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "帳本"
    }
}

extension CoBookViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let coBookCell = tableView.dequeueReusableCell(withIdentifier: "coBookCell") as? CoBookTableViewCell
        else {
            fatalError("can not create coBookCell")
        }

        // 顯示新增account book name & roomId
        coBookCell.bookNameLabel.text = data[indexPath.row].name
        coBookCell.roomIDLabel.text = "ID: \(data[indexPath.row].roomId)"

        return coBookCell
    }

    // tableView左滑刪除
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            // 順序問題，需要先偵測對應indexPath資料再進行刪除
            deleteSpecificData(indexPathRow: indexPath.row)
            data.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }
}
