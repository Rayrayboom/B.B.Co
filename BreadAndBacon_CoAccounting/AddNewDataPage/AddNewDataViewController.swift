//
//  AddNewDataViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/30.
//

import UIKit
import SwiftUI

class AddNewDataViewController: UIViewController {
    // 因為DateFormatter()非常佔記憶體也很吃效能，因此把他從cellForRowAt拉出來，放在global，這樣只要宣告一次就好，否則每次gen tableView就得生成一次
    let formatter = DateFormatter()
    var costCategory: [String] = ["金額", "種類", "帳戶"]
    var transferCategory: [String] = ["金額", "來源帳戶", "目的帳戶"]
    var segmentTag = 0
    var tapIndexpath: IndexPath?

    @IBOutlet weak var addNewDadaTableView: UITableView!

    @IBOutlet weak var sourceSegmentControl: UISegmentedControl!

    @IBAction func addNewContent(_ sender: UIButton) {
        
    }

    @IBAction func insertQRCode(_ sender: UIButton) {
        guard let presentQRCode = self.storyboard?.instantiateViewController(
            withIdentifier: "qrcodeVC") as? QRCodeViewController
        else {
            fatalError("ERROR: Can not find addDataPage.")
        }
        let navigation = UINavigationController(rootViewController: presentQRCode)
        navigation.modalPresentationStyle = .fullScreen
        present(navigation, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addNewDadaTableView.delegate = self
        addNewDadaTableView.dataSource = self
        addNewDadaTableView.estimatedRowHeight = UITableView.automaticDimension

        // segmentControl 偵測改值狀態
        sourceSegmentControl.addTarget(self, action: #selector(handelSegmentControl), for: .valueChanged)
        // 點選X時，執行取消新增
        cancelNewData()
        // datePicker的格式
        formatter.dateFormat = "yyyy 年 MM 月 dd 日"
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    // func for segmentControl 更改時切換頁面
    @objc func handelSegmentControl() {
//        print(sourceSegmentControl.selectedSegmentIndex)
        segmentTag = sourceSegmentControl.selectedSegmentIndex
        print("This is current segmentTag \(segmentTag)")
        addNewDadaTableView.reloadData()
    }

    // 取消新增資料按鈕trigger
    func cancelNewData() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(dismissPage))
    }

    // 取消並dismiss VC
    @objc func dismissPage() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}

extension AddNewDataViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tapIndexpath = indexPath
        // 點擊cell時收起鍵盤
        view.endEditing(true)
    }
}

extension AddNewDataViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 3 {
            return 250
        } else {
            return UITableView.automaticDimension
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return costCategory.count
        } else if section == 2 {
            return 1
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if segmentTag == 2 {
            if indexPath.section == 0 {
                guard let dateCell = tableView.dequeueReusableCell(
                    withIdentifier: "dateCell") as? AddNewDataTableViewCell
                else {
                    fatalError("can not create cell")
                }

                // 設定datePicker的delegate
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

                // 每次切換segment時，讓顯示金額、種類、帳戶的textField重置（意指把picker先清除），因為在生成cell時會在傳indexPath過去cell時給予對應的picker
                addDataCell.contentTextField.inputView = nil
                addDataCell.indexPath = indexPath
                addDataCell.delegate = self
                // 依照category array裡的資料筆數決定section:1有幾個cell
                addDataCell.fillInContent(name: transferCategory[indexPath.row])
                addDataCell.contentTextField.textAlignment = .center
                addDataCell.contentConfig()
                return addDataCell
// MARK: - Notice
//                addDataCell.fillInContent(name: transferCategory[indexPath.row], content: costContent[indexPath.row])

//                if indexPath.row == 0 {
//                    addDataCell.contentLabel.isHidden = true
//                    addDataCell.contentTextField.text = ""
//                    return addDataCell
//                } else {
//                    addDataCell.contentLabel.isHidden = false
//                    addDataCell.contentTextField.isHidden = true
//                    return addDataCell
//                }
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
                return detailCell
            }
        } else {
            if indexPath.section == 0 {
                guard let dateCell = tableView.dequeueReusableCell(
                    withIdentifier: "dateCell") as? AddNewDataTableViewCell
                else {
                    fatalError("can not create cell")
                }

                // 設定datePicker的delegate
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
                // 每次切換segment時，讓顯示金額、種類、帳戶的textField重置（意指把picker先清除），因為在生成cell時會在傳indexPath過去cell時給予對應的picker
                addDataCell.contentTextField.inputView = nil
                addDataCell.indexPath = indexPath
                addDataCell.delegate = self
                addDataCell.fillInContent(name: costCategory[indexPath.row])
                addDataCell.contentTextField.textAlignment = .center
                addDataCell.contentConfig()
                return addDataCell
// MARK: - Notice
//                addDataCell.fillInContent(name: costCategory[indexPath.row], content: costContent[indexPath.row])
//                if indexPath.row == 0 {
//                    addDataCell.contentLabel.isHidden = true
//                    addDataCell.contentTextField.text = ""
//                    return addDataCell
//                } else {
//                    addDataCell.contentLabel.isHidden = false
//                    addDataCell.contentTextField.isHidden = true
//                    return addDataCell
//                }
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
                return detailCell
            }
        }
    }
}

extension AddNewDataViewController: PassTextfieldDelegate {
    // 用delegate把alertVC要用到的present在這邊做，因為cell無法直接用present這個動作
    func addNewContent(_ cell: AddNewDataTableViewCell) {
        present(cell.controller, animated: true)
    }

    // 用delegate把cell和點選的sender傳過來，進行給新值的動作
    func passTextField(_ cell: AddNewDataTableViewCell, sender: UIDatePicker) {
        // 當date picker改變時，執行此func，把當前改變的date塞給textfield
        cell.dateTextfield.text = formatter.string(from: sender.date)
    }
}
