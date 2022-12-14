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
        fetchCoBook(userName: getName)
        bookTableView.reloadData()
        // 回到帳本目錄時時恢復下方tabbar
        self.tabBarController?.tabBar.isHidden = false
    }

    func setupUI() {
        view.backgroundColor = UIColor().hexStringToUIColor(hex: "EBE5D9")
        bookTableView.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        // tableView top內縮10 points
        bookTableView.contentInset = UIEdgeInsets(top: -10, left: 0, bottom: 0, right: 0)
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
            self.fetchCoBook(userName: self.getName)
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
            // 新增co_account book時儲存自動生成的document id
            let identifier = BBCoFireBaseManager.shared.createCoAccountBookData(bookNameString: self.bookName, userIdArray: self.userName)
            self.fetchCoBook(userName: self.getName)
            self.updateDataAndfetchCoBook(bookIdentifier: identifier, userId: self.getId, userContentData: self.userContent, userNameData: self.userName, userName: self.getName)
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
                let book = snapshot.documents.compactMap { snapshot in
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
                    self.updateDataAndfetchCoBook(bookIdentifier: self.specificBook[0].id, userId: self.getId, userContentData: self.userContent, userNameData: self.userName, userName: self.getName)
                    // success alert animation
                    SPAlert.successAlert()
                    print("I find the document \(self.specificBook)")
                }
            }
    }

    // 更新付款人到帳本後再fetch一次資料，並在main thread更新(等完全新增完付款者後，再去fetach一次book的資料看哪幾本有自己並顯示)
    func updateDataAndfetchCoBook(bookIdentifier: String, userId: String, userContentData: [User], userNameData: [String], userName: String) {
        data = []
        // 切換到global thread處理更新付款人
        DispatchQueue.global().async {
            let group = DispatchGroup()
            group.enter()
            BBCoFireBaseManager.shared.updateUserToBook(bookIdentifier: bookIdentifier, userId: userId, userContentData: userContentData, userNameData: userNameData) {
                group.leave()
            }
            group.wait()
            group.enter()
            BBCoFireBaseManager.shared.fetchCoBook(userName: userName) { result in
                self.data = result
                print("=== self.data", self.data)
                group.leave()
            }
            // 取得資料後回到main thread更新UI
            group.notify(queue: .main) {
                self.bookTableView.reloadData()
            }
        }
    }

    // fetch所有包含自己的共同帳本
    func fetchCoBook(userName: String) {
        data = []
        BBCoFireBaseManager.shared.fetchCoBook(userName: userName) { result in
            self.data = result
        }
    }

    func fetchBookDetail(document: String, subCollection: String) {
        bookDetail = []
        self.group.enter()
        BBCoFireBaseManager.shared.fetchBookDetail(document: document, subCollection: subCollection) { result in
            self.bookDetail = result
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
            BBCoFireBaseManager.shared.editSpecificData(bookData: self.data, indexPathRow: self.indexPathFromBook?.row ?? 0, textField: self.bookName)
            // success alert animation
            SPAlert.successAlert()
            // 修改完後再去fetch一次book data（顯示最新資料在tableView）
            self.fetchCoBook(userName: self.getName)
        }
        controller.addAction(okAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        // 記得要present後alert才會出現
        present(controller, animated: true)
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
                        BBCoFireBaseManager.shared.deleteSpecificSubcollection(bookData: self.data, indexPathRow: indexPath.row, bookDetailData: self.bookDetail, documentNum: num)
                    }
                    // 接著刪除book
                    BBCoFireBaseManager.shared.deleteSpecificData(bookData: self.data, indexPathRow: indexPath.row)
                    // 重新抓最新資料(會reloadData)
                    self.fetchCoBook(userName: self.getName)
                }
            }
            let editAction = UIAction(title: "編輯", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: .off) { action in
                self.indexPathFromBook = indexPath
                self.editAlert()
                self.fetchCoBook(userName: self.getName)
            }

            let copyAction = UIAction(title: "複製book ID", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: .off) { action in
                self.indexPathFromBook = indexPath
                self.fetchCoBook(userName: self.getName)
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
                    BBCoFireBaseManager.shared.deleteSpecificSubcollection(bookData: self.data, indexPathRow: indexPath.row, bookDetailData: self.bookDetail, documentNum: num)
                }
                // 接著刪除book
                // 順序問題，需要先偵測對應indexPath資料再進行刪除
                BBCoFireBaseManager.shared.deleteSpecificData(bookData: self.data, indexPathRow: indexPath.row)
                self.data.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.endUpdates()
            }
        }
    }
}
