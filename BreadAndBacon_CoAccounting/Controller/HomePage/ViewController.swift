//
//  ViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/28.
//

import UIKit
import FirebaseFirestore

class ViewController: UIViewController {
    // 用來存所選日期的data
    var data: [Account] = [] {
        didSet {
            group.notify(queue: .main) {
                self.dateBO.addTarget(self, action: #selector(self.tappedDateButton), for: .touchUpInside)
                self.showDetailTableView.reloadData()
            }
        }
    }
    var category: [Category] = [] {
        didSet {
            group.notify(queue: .main) {
                self.dateBO.addTarget(self, action: #selector(self.tappedDateButton), for: .touchUpInside)
                self.showDetailTableView.reloadData()
            }
        }
    }
    // 因為UIDatePicker一定要在main thread做，但group是在global執行，因此先在全域宣告一個Date型別的變數，當fetch data抓date picker的日期資料時，改用全域變數的date拿到date的資料(self.date)
    var date = Date()
    let group = DispatchGroup()
    let queueGroup = DispatchQueue.global()

    @IBOutlet weak var dateBO: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var showDetailTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // 一開啟app先去抓取firebase資料，把現有local端資訊更新為最新
        // 因為有API抓取時間差GCD問題，故用group/notice來讓API資料全部回來後再同步更新到tableView上
        self.group.enter()
        queueGroup.async(group: group) {
            self.fetchAllData()
            self.group.leave()
        }

        showDetailTableView.delegate = self
        showDetailTableView.dataSource = self

        tappedDatePicker()
        dateBO.tintColor = .black
        // 讓date button一開始顯示當天日期
        dateBO.setTitle(BBCDateFormatter.shareFormatter.string(from: datePicker.date), for: .normal)
    }

    // 點選date picker時偵測點選的狀態
    func tappedDatePicker() {
        datePicker.tintColor = .systemBrown
        datePicker.addTarget(self, action: #selector(didSelectDate(_:)), for: .valueChanged)
    }

    // 把選擇的date picker日期轉成string給button顯示
    @objc func didSelectDate(_ sender: UIDatePicker) {
        self.date = sender.date
        // 點選date picker時顯示的格式用"yyyy/MM/dd"
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy/MM/dd"
        dateBO.tintColor = .black
        dateBO.setTitle(BBCDateFormatter.shareFormatter.string(from: sender.date), for: .normal)
        // 點擊date button後會回到當天日期，需要再fetch一次data讓他呈現當天的資料
        // 因為有API抓取時間差GCD問題，故用group/notice來讓API資料全部回來後再同步更新到tableView上
        self.group.enter()
        queueGroup.async(group: group) {
            self.fetchAllData()
            self.group.leave()
        }
    }

    // 點選date button後date picker和button title會回到今天日期
    @objc func tappedDateButton(_ sender: UIDatePicker) {
        // 點選date button時顯示的格式用"yyyy/MM/dd"
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy/MM/dd"
        // 把date picker日期改為今天
        let today = Date(timeIntervalSinceNow: 0)
        datePicker.setDate(today, animated: true)
        // date button顯示今天日期
        dateBO.setTitle(BBCDateFormatter.shareFormatter.string(from: datePicker.date), for: .normal)
        // 點擊date button後會回到當天日期，需要再fetch一次data讓他呈現當天的資料
        // 因為有API抓取時間差GCD問題，故用group/notice來讓API資料全部回來後再同步更新到tableView上
        self.group.enter()
        queueGroup.async(group: group) {
            self.fetchAllData()
            self.group.leave()
        }
    }

    // 從Firebase上抓當前選擇日期的資料，並fetch資料下來
    func fetchUserSpecific(subCollection: String) {
        // fetch firebase指定條件為date的資料時，用"yyyy 年 MM 月 dd 日"格式來偵測
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
        let dataBase = Firestore.firestore()
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
            }
    }

    // 從Firebase上fetch全部種類/帳戶資料
    func fetchUser(subCollection: String) {
        let dataBase = Firestore.firestore()
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
            }
    }

    func fetchAllData() {
        // 點選新的日期時，先把存資料、種類的array清空，讓新fetch data塞最新資料，才不會一直append下去
        data = []
        category = []
        fetchUserSpecific(subCollection: "expenditure")
        fetchUser(subCollection: "expenditure")
        fetchUserSpecific(subCollection: "revenue")
        fetchUser(subCollection: "revenue")
        fetchUserSpecific(subCollection: "account")
        fetchUser(subCollection: "account")
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let presentEditVC = self.storyboard?.instantiateViewController(withIdentifier: "editVC") as? EditViewController else {
            fatalError("can not find editVC")
        }
        presentEditVC.data = data
        presentEditVC.category = category

        let navigation = UINavigationController(rootViewController: presentEditVC)
        navigation.modalPresentationStyle = .overFullScreen
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
}
