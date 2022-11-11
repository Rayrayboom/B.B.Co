//
//  CoBookViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/11.
//

import UIKit
import FirebaseFirestore

class CoBookViewController: UIViewController {
    var data: [Book] = [] {
        didSet {
            print(data)
            bookTableView.reloadData()
        }
    }
    var bookDetail: [Account] = []

    // 用來存現有的user
    var userContent: [User] = []
    var userId: [String] = []

    @IBOutlet weak var bookTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        bookTableView.delegate = self
        bookTableView.dataSource = self
        fetchUser()
        saveEditData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        fetchCoBook()
        bookTableView.reloadData()
    }

// TODO: - 需讓使用者輸入book name
    // 按下右上button來新增帳本
    func saveEditData() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(saveEdit))
    }

    // 觸發新增帳本func
    @objc func saveEdit() {
        createCoAccountData()
    }

    // MARK: - 上傳 book id & user_id 到Firebase
    func createCoAccountData() {
        let dataBase = Firestore.firestore()
        let fetchDocumentID = dataBase.collection("co-account").document()
        // 讓swift code先去生成一組id並存起來，後續要識別document修改資料用
        let identifier = fetchDocumentID.documentID
        // 需存id，後續delete要抓取ID刪除對應資料
        let book = Book(id: identifier, userId: userId)
        do {
            try fetchDocumentID.setData(from: book)
            print("success create document. ID: \(fetchDocumentID.documentID)")
        } catch {
            print(error)
        }
    }

    // 從Firebase上fetch全部user資料，要放進帳本的user_id(這本帳本有多少人有存取權限)
    func fetchUser() {
        userId = []
        let dataBase = Firestore.firestore()
        dataBase.collection("user")
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let user = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: User.self)
                }

                self.userContent.append(contentsOf: user)
                for num in 0..<self.userContent.count {
                    self.userId.append(self.userContent[num].id ?? "")
                }
            }
    }

    // 從Firebase上fetch有幾本帳本book
    func fetchCoBook() {
        data = []
        let dataBase = Firestore.firestore()
        dataBase.collection("co-account")
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

        coBookCell.bookNameLabel.text = data[indexPath.row].id

        return coBookCell
    }
}
