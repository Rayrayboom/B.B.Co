//
//  ViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/28.
//

import UIKit
import FirebaseFirestore

protocol ViewControllerDelegate: AnyObject {
    func getDate(currentDate: String)
}

class ViewController: UIViewController {
    weak var delegate: ViewControllerDelegate?
    // 用來存所選日期的data
    var data: [Account] = [] {
        didSet {
            self.showDetailTableView.reloadData()
        }
    }
    var category: [Category] = [] {
        didSet {
            self.showDetailTableView.reloadData()
        }
    }
    // 因為UIDatePicker一定要在main thread做，但group是在global執行，因此先在全域宣告一個Date型別的變數，當fetch data抓date picker的日期資料時，改用全域變數的date拿到date的資料(self.date)
    var date = Date()
    let group = DispatchGroup()
//    let queueGroup = DispatchQueue.global()
// MARK: - 注意！
    var month: String = ""

    @IBOutlet weak var dateBO: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var showDetailTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        showDetailTableView.delegate = self
        showDetailTableView.dataSource = self

        tappedDatePicker()
        dateBO.tintColor = .black
        // 讓date button一開始顯示當天日期
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy/MM/dd"
        dateBO.setTitle(BBCDateFormatter.shareFormatter.string(from: datePicker.date), for: .normal)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 一開啟app先去抓取firebase資料，把現有local端資訊更新為最新
        self.fetchAllData()
    }

    // 點選date picker時偵測點選的狀態
    func tappedDatePicker() {
        datePicker.tintColor = .systemBrown
        datePicker.addTarget(self, action: #selector(didSelectDate(_:)), for: .valueChanged)
    }

    // 把選擇的date picker日期轉成string給button顯示
    @objc func didSelectDate(_ sender: UIDatePicker) {
        self.date = sender.date
        // 使用UserDefaults方式：先把homeVC的當前點選date存在UserDefaults，當跳到addNewDataVC時再把date拿過來用
        UserDefaults.standard.set(self.date, forKey: "currentDate")
        // 點選date picker時顯示的格式用"yyyy/MM/dd"
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy/MM/dd"
        dateBO.tintColor = .black
        dateBO.setTitle(BBCDateFormatter.shareFormatter.string(from: sender.date), for: .normal)

        self.fetchAllData()
    }

    // 點選date button後date picker和button title會回到今天日期
    @objc func tappedDateButton(_ sender: UIDatePicker) {
        // 點選date button時顯示的格式用"yyyy/MM/dd"
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy/MM/dd"
        // 把date picker日期改為今天
        let today = Date(timeIntervalSinceNow: 0)
        // 按下date button之後要把當天date的值(let today)給外部變數的date，因為在fetch指定日期data時是抓date的日期
        date = today
        // 按下date button之後要把date picker顯示的顏色區塊改為當天
        datePicker.setDate(today, animated: true)
        // date button顯示date picker拿到的日期(也就是today的日期)
        dateBO.setTitle(BBCDateFormatter.shareFormatter.string(from: datePicker.date), for: .normal)
        // 點擊date button後會回到當天日期，需要再fetch一次data讓他呈現當天的資料
            self.fetchAllData()
    }

    // 從Firebase上抓當前選擇日期的資料，並fetch資料下來
    func fetchUserSpecific(subCollection: String) {
// MARK: - 注意！
//        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月"
//        month = BBCDateFormatter.shareFormatter.string(from: self.date)

        // fetch firebase指定條件為date的資料時，用"yyyy 年 MM 月 dd 日"格式來偵測
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
        let dataBase = Firestore.firestore()
        // 因為有API抓取時間差GCD問題，故用group/notice來讓API資料全部回來後再同步更新到tableView上
        // 進入group
        self.group.enter()
        // 因為UIDatePicker一定要在main thread做，但group是在global執行，因此先在全域宣告一個Date型別的變數，當fetch data抓date picker的日期資料時，改用全域變數的date拿到date的資料(self.date)
        dataBase.collection("user/vy4oSHvNXfzBAKzwj95x/\(subCollection)")
            .whereField("date", isEqualTo: BBCDateFormatter.shareFormatter.string(from: self.date))
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let account = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Account.self)
                }
                self.data.append(contentsOf: account)
                print("data here \(self.data)")
                // 每一支API打完之後leave group
                self.group.leave()
            }
    }

    // 從Firebase上fetch全部種類/帳戶資料
    func fetchUserCategory(subCollection: String) {
        let dataBase = Firestore.firestore()
        // 因為有API抓取時間差GCD問題，故用group/notice來讓API資料全部回來後再同步更新到tableView上
        // 進入group
        self.group.enter()
        dataBase.collection("user/vy4oSHvNXfzBAKzwj95x/\(subCollection)_category")
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let category = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Category.self)
                }
                self.category.append(contentsOf: category)
                print("category here \(self.category)")
                // 每一支API打完之後leave group
                self.group.leave()
            }
    }

    func fetchAllData() {
        // 點選新的日期時，先把存資料、種類的array清空，讓新fetch data塞最新資料，才不會一直append下去
        data = []
        category = []
        fetchUserSpecific(subCollection: "expenditure")
        fetchUserCategory(subCollection: "expenditure")
        fetchUserSpecific(subCollection: "revenue")
        fetchUserCategory(subCollection: "revenue")
        fetchUserSpecific(subCollection: "account")
        fetchUserCategory(subCollection: "account")

        // notify放這邊是因為要等所有API執行完後再執行button點選觸發的功能
        group.notify(queue: .main) {
            self.dateBO.addTarget(self, action: #selector(self.tappedDateButton), for: .touchUpInside)
            self.showDetailTableView.reloadData()
        }
    }

    // 從firebase上刪除資料，delete firebase data需要一層一層找，不能用路徑
    func deleteSpecificData(subCollection: String, indexPathRow: Int) {
        let dataBase = Firestore.firestore()
        let documentRef = dataBase.collection("user").document("vy4oSHvNXfzBAKzwj95x").collection(subCollection).document(data[indexPathRow].id)
        documentRef.delete()
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let presentEditVC = self.storyboard?.instantiateViewController(withIdentifier: "editVC") as? EditViewController else {
            fatalError("can not find editVC")
        }
        // 把homeVC自己傳給editVC
        presentEditVC.homeVC = self
        // 點擊哪個row就把data array對應row的資料傳給editVC
        presentEditVC.data = data[indexPath.row]
        presentEditVC.category = category

        let navigation = UINavigationController(rootViewController: presentEditVC)
        navigation.modalPresentationStyle = .fullScreen
        present(navigation, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let homeDetailCell = tableView.dequeueReusableCell(withIdentifier: "homeDetailCell") as? HomeDetailTableViewCell else {
            fatalError("can not create cell")
        }

        homeDetailCell.categoryImage.image = UIImage(systemName: "hand.thumbsup.fill")
        homeDetailCell.nameLabel.text = data[indexPath.row].category
        homeDetailCell.amountLabel.text = data[indexPath.row].amount
        homeDetailCell.detailLabel.text = data[indexPath.row].detail

        return homeDetailCell
    }

    // tableView右滑刪除
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            // 順序問題，需要先偵測對應indexPath資料再進行刪除
            deleteSpecificData(subCollection: "expenditure", indexPathRow: indexPath.row)
            deleteSpecificData(subCollection: "revenue", indexPathRow: indexPath.row)
            deleteSpecificData(subCollection: "account", indexPathRow: indexPath.row)
            data.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }
}
