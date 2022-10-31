//
//  AddNewDataViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/30.
//

import UIKit
import SwiftUI

class AddNewDataViewController: UIViewController {
    //因為DateFormatter()非常佔記憶體也很吃效能，因此把他從cellForRowAt拉出來，放在global，這樣只要宣告一次就好，否則每次gen tableView就得生成一次
    let formatter = DateFormatter()
    let category: [String] = ["金額", "種類", "帳戶"]

    @IBOutlet weak var addNewDadaTableView: UITableView!

    @IBOutlet weak var sourceSegmentControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        addNewDadaTableView.delegate = self
        addNewDadaTableView.dataSource = self
        addNewDadaTableView.estimatedRowHeight = UITableView.automaticDimension

        // segmentControl 偵測改值狀態
        sourceSegmentControl.addTarget(self, action: #selector(handelSegmentControl), for: .valueChanged)
        // 點選X時，執行取消新增
        cancelNewData()
        formatter.dateFormat = "dd/MM/yyyy"
    }

    // func for segmentControl 更改時切換頁面
    @objc func handelSegmentControl() {
        print(sourceSegmentControl.selectedSegmentIndex)

//        switch sourceSegmentControl.selectedSegmentIndex {
//        case 0:
//
//        case 1:
//
//        default:
//            <#code#>
//        }
    addNewDadaTableView.reloadData()
    }

    // 取消新增資料按鈕trigger
    func cancelNewData() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(dismissPage))
    }

    // 取消新增func並dismiss VC
    @objc func dismissPage() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}

extension AddNewDataViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
    }
}

extension AddNewDataViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return category.count
        } else if section == 2 {
            return 1
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let dateCell = tableView.dequeueReusableCell(
                withIdentifier: "dateCell") as? AddNewDataTableViewCell
            else {
                fatalError("can not create cell")
            }

            dateCell.delegate = self
            let date = Date()
            // formatter把日期(date)轉成String塞給dateStr
            let dateStr = formatter.string(from: date)
            // 把存著date的dateStr用cell的func config()塞值給cell裡面的textField
            dateCell.config(dateStr: dateStr)
            return dateCell
        } else if indexPath.section == 1 {
            guard let addDataCell = tableView.dequeueReusableCell(
                withIdentifier: "addDataCell") as? AddNewDataTableViewCell
            else {
                fatalError("can not create cell")
            }
            // 依照category array裡的資料筆數決定section:1有幾個cell
            addDataCell.fillInContent(name: category[indexPath.row])
            return addDataCell
        } else if indexPath.section == 2 {
            guard let qrCell = tableView.dequeueReusableCell(
                withIdentifier: "QRCell") as? AddNewDataTableViewCell
            else {
                fatalError("can not create cell")
            }
//            qrCell.qrButton.setImage(UIImage(systemName: "qrcode.viewfinde"), for: .normal)
            return qrCell
        } else {
            guard let detailCell = tableView.dequeueReusableCell(
                withIdentifier: "detailCell") as? AddNewDataTableViewCell
            else {
                fatalError("can not create cell")
            }
            detailCell.detailTextView.text = "Lorem ipsum dolor sit er elit lamet, consectetaur"
            tableView.rowHeight = 250
            return detailCell
        }
    }
}

extension AddNewDataViewController: PassTextfieldDelegate {
    // 用delegate把cell和點選的sender傳過來，進行給新值的動作
    @objc func passTextField(_ cell: AddNewDataTableViewCell, sender: UIDatePicker) {
        // 當date picker改變時，執行此func，把當前改變的date塞給textfield
        cell.dateTextfield.text = formatter.string(from: sender.date)
    }
}
