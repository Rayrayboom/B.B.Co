//
//  CoBookViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/11.
//

import UIKit
import FirebaseFirestore
import SwiftKeychainWrapper
import SPAlert

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
    // 生成refreshControl實例
    var refreshControl = UIRefreshControl()
    // 用來存當前點選的cell indexPath
    var indexPathFromBook: IndexPath?

    @IBOutlet weak var bookTableView: UITableView!
    @IBOutlet weak var remindLabel: UILabel!
    
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
        // 加上refreshControl下拉更新(重fetch data)
        refreshBooks()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        BBCoLoading.loading(view: self.view)
        fetchCoBook()
        bookTableView.reloadData()
        // 回到帳本目錄時時恢復下方tabbar
        self.tabBarController?.tabBar.isHidden = false
    }

    func setupUI() {
        view.backgroundColor = UIColor().hexStringToUIColor(hex: "EBE5D9")
        bookTableView.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
    }
    // MARK: -待確認要放在哪裡才會顯示對的功能
    // 當日尚無資料者顯示“目前還沒共同帳本”
    func checkDataCount() {
        if self.data.isEmpty {
            self.remindLabel.isHidden = false
        } else {
            self.remindLabel.isHidden = true
        }
    }

    // 加上refreshControl下拉更新(重fetch data)
    func refreshBooks() {
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        bookTableView.addSubview(refreshControl)
    }

    // refreshControl func
    @objc func refresh(sender: UIRefreshControl) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchCoBook()
            self.refreshControl.endRefreshing()
        }
    }

    // 按下右上button讓使用者輸入book name並新增帳本
    func addNewCoAccountBook() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "ADD_coData_1"), style: .plain, target: self, action: #selector(saveEdit))
    }

    // 觸發新增帳本func
    @objc func saveEdit() {
        addCoAccountingBookAlert()
    }

    // 新增帳本的alert，讓使用者輸入帳本名稱
    func addCoAccountingBookAlert() {
        controller = UIAlertController(title: "新增帳本", message: nil, preferredStyle: .alert)
        controller.addTextField { textField in
            textField.placeholder = "帳本名稱"
            textField.keyboardType = UIKeyboardType.default
            textField.keyboardAppearance = .dark
        }
        // 按下OK執行新增account book(使用者輸入accounnt book name)
        let okAction = UIAlertAction(title: "新增", style: .default) { [unowned controller] _ in
            self.bookName = controller.textFields?[0].text ?? ""
            self.createCoAccountData()
            self.fetchCoBook()
            // 按下新增帳本時，在該帳本的付款人會先預設加上本人
            self.updateUserToBook(bookIdentifier: self.identifier)
            // success alert animation
            SPAlert.successAlert()
        }
        controller.addAction(okAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        // 記得要present後alert才會出現
        present(controller, animated: true)
    }

    // 按下左上button讓使用者輸入帳本id來加入帳本
    func joinCoAccountBook() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Accounting_book_2"), style: .plain, target: self, action: #selector(checkRoomId))
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
            textField.keyboardAppearance = .dark
        }
        // 按下OK執行新增account book(使用者輸入accounnt book name)
        let okAction = UIAlertAction(title: "加入", style: .default) { [unowned controller] _ in
            self.inputBookID = controller.textFields?[0].text ?? ""
            self.fetchBookSpecific(collection: "co-account", field: "room_id", inputID: self.inputBookID)
        }
        controller.addAction(okAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
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
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let snapshot = snapshot else {
                    return
                }
                var book = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Book.self)
                }

                // error handle，輸入book ID錯誤時，跳出提醒視窗
                if book.isEmpty {
                    self.controller = UIAlertController(title: "book ID 錯誤", message: "沒有這本帳本哦，請再輸入一次", preferredStyle: .alert)
                    // 建立[確認]按鈕
                    let okAction = UIAlertAction(
                        title: "我知道了",
                        style: .default, handler: nil)
                    self.controller.addAction(okAction)
                    // 顯示提示框
                    self.present(self.controller, animated: true, completion: nil)
                } else {
                    // book ID輸入正確的話就執行updateUserToBook func
                    self.specificBook.append(contentsOf: book)
                    self.updateUserToBook(bookIdentifier: self.specificBook[0].id)
                    // success alert animation
                    SPAlert.successAlert()
                    print("I find the document \(self.specificBook)")
                }
            }
    }

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

    // 從Firebase上fetch有幾本帳本user id是有我自己的(因為user_id是array，因此要用whereField-arrayContains來判斷array裡的元素)
    func fetchCoBook() {
        data = []
        let dataBase = Firestore.firestore()
        self.group.enter()
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
                self.group.leave()
            }
    }

    // 從Firebase上fetch對應book的detail資料
    func fetchBookDetail(document: String, subCollection: String) {
        bookDetail = []
        let dataBase = Firestore.firestore()
        self.group.enter()
        dataBase.collection("co-account/\(document)/\(subCollection)")
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let account = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Account.self)
                }
                self.bookDetail.append(contentsOf: account)
                print("book datail here \(self.data)")
                self.group.leave()
            }
    }

    // 編輯cell的alert
    func editAlert() {
        controller = UIAlertController(title: "編輯帳本名稱", message: nil, preferredStyle: .alert)
        controller.addTextField { textField in
            textField.placeholder = "請輸入想編輯的名稱"
            textField.keyboardType = UIKeyboardType.default
            textField.keyboardAppearance = .dark
        }
        guard let cell = bookTableView.cellForRow(at: indexPathFromBook ?? IndexPath()) as? CoBookTableViewCell
        else {
            fatalError("can not find CoBookTableViewCell")
        }

        let okAction = UIAlertAction(title: "修改", style: .default) { [unowned controller] _ in
            // 把輸入textField的資料給bookName
            self.bookName = controller.textFields?[0].text ?? ""
            // 更新firebase對應document的book name
            self.editSpecificData(indexPathRow: self.indexPathFromBook?.row ?? 0, textField: self.bookName)
            // success alert animation
            SPAlert.successAlert()
            // 修改完後再去fetch一次book data（顯示最新資料在tableView）
            self.fetchCoBook()
        }
        controller.addAction(okAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        // 記得要present後alert才會出現
        present(controller, animated: true)
    }

    // 針對對應的book cell編輯
    func editSpecificData(indexPathRow: Int, textField: String) {
        let dataBase = Firestore.firestore()
        dataBase.collection("co-account").document(data[indexPathRow].id).updateData(["name": textField ]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document update successfully")
            }
        }
    }

    // 從firebase上刪除指定document，delete firebase data需要一層一層找，不能用路徑
    func deleteSpecificData(indexPathRow: Int) {
        let dataBase = Firestore.firestore()
        let documentRef = dataBase.collection("co-account").document(data[indexPathRow].id)
        documentRef.delete()
    }

    // 從firebase上刪除document底下的subCollection，delete firebase data需要一層一層找，不能用路徑
    func deleteSpecificSubcollection(indexPathRow: Int, documentNum: Int) {
        let dataBase = Firestore.firestore()
        let documentRef = dataBase.collection("co-account").document(data[indexPathRow].id).collection("co_expenditure").document(bookDetail[documentNum].id)
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

        navigationController?.pushViewController(pushCoAccountingVC, animated: true)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "我的帳本"
    }

    // 長按tableView cell叫出刪除、編輯功能
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions -> UIMenu? in
            let deleteAction = UIAction(title: "刪除", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: .off) { action in
                self.fetchBookDetail(document: self.data[indexPath.row].id, subCollection: "co_expenditure")
                self.group.notify(queue: .main) {
                    // 先把subcollection裡面的document一筆一筆刪除
                    for num in 0..<self.bookDetail.count {
                        self.deleteSpecificSubcollection(indexPathRow: indexPath.row, documentNum: num)
                    }
                    // 接著刪除book
                    self.deleteSpecificData(indexPathRow: indexPath.row)
                    // 重新抓最新資料(會reloadData)
                    self.fetchCoBook()
                }
            }
            let editAction = UIAction(title: "編輯", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: .off) { action in
                self.indexPathFromBook = indexPath
                self.editAlert()
                self.fetchCoBook()
            }

            let copyAction = UIAction(title: "複製book ID", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: .off) { action in
                self.indexPathFromBook = indexPath
                self.fetchCoBook()
                self.group.notify(queue: .main) {
                    UIPasteboard.general.string = self.data[indexPath.row].roomId
                }
            }
            
            return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: [deleteAction, editAction, copyAction])
        }
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
        coBookCell.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")

        // 顯示新增account book name & roomId
        coBookCell.bookNameLabel.text = data[indexPath.row].name
        coBookCell.roomIDLabel.text = "ID: \(data[indexPath.row].roomId)"
        coBookCell.coImageView.image = UIImage(named: "CoAcc-clicked")

        return coBookCell
    }

    // tableView左滑刪除
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.fetchBookDetail(document: self.data[indexPath.row].id, subCollection: "co_expenditure")
            self.group.notify(queue: .main) {
                tableView.beginUpdates()
                // 先把subcollection裡面的document一筆一筆刪除
                for num in 0..<self.bookDetail.count {
                    self.deleteSpecificSubcollection(indexPathRow: indexPath.row, documentNum: num)
                }
                // 接著刪除book
                // 順序問題，需要先偵測對應indexPath資料再進行刪除
                self.deleteSpecificData(indexPathRow: indexPath.row)
                self.data.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.endUpdates()
            }
        }
    }
}
