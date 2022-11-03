//
//  ViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/28.
//

import UIKit
import FirebaseFirestore

class ViewController: UIViewController {
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
        dateBO.setTitle(BBCDateFormatter.shareFormatter.string(from: datePicker.date), for: .normal)
        dateBO.addTarget(self, action: #selector(tappedDateButton), for: .touchUpInside)
    }

    // 點選date picker時偵測點選的狀態
    func tappedDatePicker() {
        datePicker.tintColor = .systemBrown
        datePicker.addTarget(self, action: #selector(didSelectDate(_:)), for: .valueChanged)
    }

    // 把選擇的date picker日期轉成string給button顯示
    @objc func didSelectDate(_ sender: UIDatePicker) {
        // 點選date picker時顯示的格式用"yyyy/MM/dd"
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy/MM/dd"
        dateBO.tintColor = .black
        dateBO.setTitle(BBCDateFormatter.shareFormatter.string(from: sender.date), for: .normal)
        fetchUser()
    }

    // 點選date button後date picker和button title會回到今天日期
    @objc func tappedDateButton(_ sender: UIDatePicker) {
        // 把date picker日期改為今天
        let today = Date(timeIntervalSinceNow: 0)
        datePicker.setDate(today, animated: true)
        // date button顯示今天日期
        dateBO.setTitle(BBCDateFormatter.shareFormatter.string(from: datePicker.date), for: .normal)
    }

    // 從Firebase上抓當前選擇日期的資料，並fetch資料下來
    func fetchUser() {
        // fetch firebase指定條件為date的資料時，用"yyyy 年 MM 月 dd 日"格式來偵測
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
        let db = Firestore.firestore()
        db.collection("user/vy4oSHvNXfzBAKzwj95x/expenditure").whereField("date", isEqualTo: BBCDateFormatter.shareFormatter.string(from: datePicker.date)).getDocuments { snapshot, error in
            guard let snapshot = snapshot else {
                return
            }
            let account = snapshot.documents.compactMap { snapshot in
                try? snapshot.data(as: Account.self)
            }
            print(account)
        }
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let homeDetailCell = tableView.dequeueReusableCell(withIdentifier: "homeDetailCell") as? HomeDetailTableViewCell else {
            fatalError("can not create cell")
        }

        return homeDetailCell
    }
}
