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
    // 宣告一個alertVC
    var controller = UIAlertController()
    var bookName: String = ""

    @IBOutlet weak var bookTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        bookTableView.delegate = self
        bookTableView.dataSource = self
        fetchUser()
        // 新增共同帳本func
        addNewCoAccountBook()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        fetchCoBook()
        bookTableView.reloadData()
        // 回到帳本目錄時時恢復下方tabbar
        self.tabBarController?.tabBar.isHidden = false
    }

// TODO: - 需讓使用者輸入book name
    // 按下右上button來新增帳本
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
        }
        controller.addAction(okAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        // 記得要present後alert才會出現
        present(controller, animated: true)
    }


    // MARK: - 上傳 book id & user_id 到Firebase
    func createCoAccountData() {
        let dataBase = Firestore.firestore()
        let documentID = dataBase.collection("co-account").document()
        // 讓swift code先去生成一組id並存起來，後續要識別document修改資料用
        let identifier = documentID.documentID
//        let prefixID = documentID.document(identifier.prefix(5))
        // 需存id，後續delete要抓取ID刪除對應資料
        let book = Book(id: identifier, name: bookName, userId: userId)
        do {
            try documentID.setData(from: book)
            print("success create document. ID: \(documentID.documentID)")
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

        // 顯示新增account book name
        coBookCell.bookNameLabel.text = data[indexPath.row].name

        return coBookCell
    }

    // tableView右滑刪除
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
