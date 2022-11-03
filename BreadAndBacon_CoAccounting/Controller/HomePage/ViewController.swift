//
//  ViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/28.
//

import UIKit
import FirebaseFirestore

class ViewController: UIViewController {
    // 因為DateFormatter()非常佔記憶體也很吃效能，因此把他從cellForRowAt拉出來，放在global，這樣只要宣告一次就好，否則每次gen tableView就得生成一次
    let formatter = DateFormatter()

    @IBOutlet weak var dateBO: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var showDetailTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        formatter.dateFormat = "yyyy/MM/dd"
        tappedDatePicker()
        dateBO.tintColor = .black
        // 讓date button一開始顯示當天日期
        dateBO.setTitle(formatter.string(from: datePicker.date), for: .normal)
        dateBO.addTarget(self, action: #selector(tappedDateButton), for: .touchUpInside)
    }

    // 點選date picker時偵測點選的狀態
    func tappedDatePicker() {
        datePicker.tintColor = .systemBrown
        datePicker.addTarget(self, action: #selector(didSelectDate(_:)), for: .valueChanged)
    }

    // 把選擇的date picker日期轉成string給button顯示
    @objc func didSelectDate(_ sender: UIDatePicker) {
        dateBO.tintColor = .black
        dateBO.setTitle(formatter.string(from: sender.date), for: .normal)
    }

    // 點選date button後date picker和button title會回到今天日期
    @objc func tappedDateButton(_ sender: UIDatePicker) {
        // 把date picker日期改為今天
        let today = Date(timeIntervalSinceNow: 0)
        datePicker.setDate(today, animated: true)
        // date button顯示今天日期
        dateBO.setTitle(formatter.string(from: datePicker.date), for: .normal)
    }
}
