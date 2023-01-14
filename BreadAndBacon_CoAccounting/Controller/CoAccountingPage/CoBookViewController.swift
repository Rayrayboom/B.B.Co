//
//  CoBookViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/11.
//

import UIKit
import SwiftKeychainWrapper
import SPAlert

class CoBookViewController: UIViewController {
    var data: [Book] = [] {
        didSet {
            bookTableView.reloadData()
        }
    }
    var bookDetail: [Account] = []
    var userContent: [User] = []
    var userName: [String] = []
    var controller = UIAlertController()
    var bookName: String = ""
    var inputBookID: String = ""
    var specificBook: [Book] = []
    var getId: String = ""
    var getName: String = ""
    let group = DispatchGroup()
    var refreshControl = UIRefreshControl()
    var indexPathFromBook: IndexPath?

    @IBOutlet weak var bookTableView: UITableView!
    @IBOutlet weak var remindLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getId = KeychainWrapper.standard.string(forKey: "id") ?? ""
        getName = KeychainWrapper.standard.string(forKey: "name") ?? ""
        bookTableView.delegate = self
        bookTableView.dataSource = self
        addNewCoAccountBook()
        joinCoAccountBook()
        refreshBooks()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        BBCoLoading.loading(view: self.view)
        fetchCoBook(userName: getName)
        bookTableView.reloadData()
        self.tabBarController?.tabBar.isHidden = false
    }

    func setupUI() {
        view.backgroundColor = UIColor().hexStringToUIColor(hex: "EBE5D9")
        bookTableView.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        bookTableView.contentInset = UIEdgeInsets(top: -10, left: 0, bottom: 0, right: 0)
    }

    func checkDataCount() {
        if self.data.isEmpty {
            self.remindLabel.isHidden = false
        } else {
            self.remindLabel.isHidden = true
        }
    }

    func refreshBooks() {
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        bookTableView.addSubview(refreshControl)
    }

    @objc func refresh(sender: UIRefreshControl) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchCoBook(userName: self.getName)
            self.refreshControl.endRefreshing()
        }
    }

    func addNewCoAccountBook() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "ADD_coData_1"), style: .plain, target: self, action: #selector(saveEdit))
    }

    @objc func saveEdit() {
        addCoAccountingBookAlert()
    }

    func addCoAccountingBookAlert() {
        controller = UIAlertController(title: "新增帳本", message: nil, preferredStyle: .alert)
        controller.addTextField { textField in
            textField.placeholder = "帳本名稱"
            textField.keyboardType = UIKeyboardType.default
            textField.keyboardAppearance = .dark
        }
        let okAction = UIAlertAction(title: "新增", style: .default) { [unowned controller] _ in
            self.bookName = controller.textFields?[0].text ?? ""
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

    func joinCoAccountBook() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Accounting_book_2"), style: .plain, target: self, action: #selector(checkRoomId))
    }

    @objc func checkRoomId() {
        joinCoAccountingBookAlert()
    }

    func joinCoAccountingBookAlert() {
        controller = UIAlertController(title: "Co-Account book ID", message: "請輸入帳本ID加入共同記帳", preferredStyle: .alert)
        controller.addTextField { textField in
            textField.placeholder = "Account book ID"
            textField.keyboardType = UIKeyboardType.default
            textField.keyboardAppearance = .dark
        }
        let okAction = UIAlertAction(title: "加入", style: .default) { [unowned controller] _ in
            self.inputBookID = controller.textFields?[0].text ?? ""
            self.checkBookSpecific(collection: "co-account", field: "room_id", inputID: self.inputBookID)
        }
        controller.addAction(okAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        present(controller, animated: true)
    }

    func checkBookSpecific(collection: String, field: String, inputID: String) {
        group.enter()
        BBCoFireBaseManager.shared
            .fetchBookSpecific(collection: collection, field: field, inputID: inputID) { result in
                self.specificBook = result
                self.group.leave()
            }
        group.notify(queue: .main) {
            self.checkCorrectBook(book: self.specificBook)
            self.bookTableView.reloadData()
        }
    }
    
    func checkCorrectBook(book: [Book]) {
        if book.isEmpty {
            self.controller = UIAlertController(title: "book ID 錯誤", message: "沒有這本帳本哦，請再輸入一次", preferredStyle: .alert)
            let okAction = UIAlertAction(
                title: "我知道了",
                style: .default, handler: nil)
            self.controller.addAction(okAction)
            self.present(self.controller, animated: true, completion: nil)
        } else {
            self.updateDataAndfetchCoBook(bookIdentifier: book[0].id, userId: self.getId, userContentData: self.userContent, userNameData: self.userName, userName: self.getName)
            SPAlert.successAlert()
        }
    }

    func updateDataAndfetchCoBook(bookIdentifier: String, userId: String, userContentData: [User], userNameData: [String], userName: String) {
        data = []
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
            group.notify(queue: .main) {
                self.bookTableView.reloadData()
            }
        }
    }

    func fetchCoBook(userName: String) {
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
            self.bookName = controller.textFields?[0].text ?? ""
            BBCoFireBaseManager.shared.editSpecificData(bookData: self.data, indexPathRow: self.indexPathFromBook?.row ?? 0, textField: self.bookName)
            SPAlert.successAlert()
            self.fetchCoBook(userName: self.getName)
        }
        controller.addAction(okAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        present(controller, animated: true)
    }
}

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

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions -> UIMenu? in
            let deleteAction = UIAction(title: "刪除", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: .off) { action in
                self.fetchBookDetail(document: self.data[indexPath.row].id, subCollection: "co_expenditure")
                self.group.notify(queue: .main) {
                    for num in 0..<self.bookDetail.count {
                        BBCoFireBaseManager.shared.deleteSpecificSubcollection(bookData: self.data, indexPathRow: indexPath.row, bookDetailData: self.bookDetail, documentNum: num)
                    }
                    BBCoFireBaseManager.shared.deleteSpecificData(bookData: self.data, indexPathRow: indexPath.row)
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
                SPAlert.successAlert()
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

        coBookCell.bookNameLabel.text = data[indexPath.row].name
        coBookCell.roomIDLabel.text = "ID: \(data[indexPath.row].roomId)"
        coBookCell.coImageView.image = UIImage(named: "CoAcc-clicked")
        coBookCell.menberQuantity.text = "成員: \(data[indexPath.row].userId.count) 人"

        return coBookCell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.fetchBookDetail(document: self.data[indexPath.row].id, subCollection: "co_expenditure")
            self.group.notify(queue: .main) {
                tableView.beginUpdates()
                for num in 0..<self.bookDetail.count {
                    BBCoFireBaseManager.shared.deleteSpecificSubcollection(bookData: self.data, indexPathRow: indexPath.row, bookDetailData: self.bookDetail, documentNum: num)
                }
                BBCoFireBaseManager.shared.deleteSpecificData(bookData: self.data, indexPathRow: indexPath.row)
                self.data.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.endUpdates()
            }
        }
    }
}
