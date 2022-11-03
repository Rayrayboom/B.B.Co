//
//  AddNewDataViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/30.
//

import UIKit
import SwiftUI
import AVFoundation
import Vision
import VisionKit
import FirebaseFirestore


// MARK: - expenditure
struct NewDataModel {
    var contentTextField: String = ""
    // date改用string型別存取，因為只需要存"年/月/日"，存時間"時/分"的話後續無法抓取資料
    var dateTime: String = ""
    var titleLabel: String = ""
    var detailTextView: String = ""
    var latestElement: String = ""
}

class AddNewDataViewController: UIViewController, VNDocumentCameraViewControllerDelegate {
    // 因為DateFormatter()非常佔記憶體也很吃效能，因此把他從cellForRowAt拉出來，放在global，這樣只要宣告一次就好，否則每次gen tableView就得生成一次
    let formatter = DateFormatter()
    var costCategory: [String] = ["金額", "種類", "帳戶"]
    var transferCategory: [String] = ["金額", "來源帳戶", "目的帳戶"]
    var costContent: [String] = ["早餐", "午餐", "晚餐"]
    var accountContent: [String] = ["現金", "信用卡", "悠遊卡"]
    var segmentTag = 0
    var tapIndexpath: IndexPath?
    var data = NewDataModel()


    @IBOutlet weak var addNewDadaTableView: UITableView!

    @IBOutlet weak var sourceSegmentControl: UISegmentedControl!

    @IBAction func insertQRCode(_ sender: UIButton) {
//        guard let presentQRCode = self.storyboard?.instantiateViewController(
//            withIdentifier: "qrcodeVC") as? QRCodeViewController
//        else {
//            fatalError("ERROR: Can not find addDataPage.")
//        }
        // 建立一個VNDocumentCameraViewController實例，並執行delegate，delegate會導到QRCodeVC去執行process image的func
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = self
        present(documentCameraViewController, animated: true)
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
        // 點選+時，執行新增資料到firebase
        saveNewData()
        // datePicker的格式
        formatter.dateFormat = "yyyy 年 MM 月 dd 日"
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    // func for segmentControl 更改時切換頁面
    @objc func handelSegmentControl() {
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

    // 新增資料按鈕trigger
    func saveNewData() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(savePage))
    }

    // 新增並上傳firebase，用segmentTag來辨識要存到哪個document裡面
    @objc func savePage() {
        switch segmentTag {
        case 0:
            createUserData(subCollection: "expenditure")
        case 1:
            createUserData(subCollection: "revenue")
        default:
            createUserData(subCollection: "account")
        }
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    // 上傳資料到Firebase
    // MARK: - 測試支出寫入firebase
    func createUserData(subCollection: String) {
        let db = Firestore.firestore()
        let fetchDocumentID = db.collection("user").document("vy4oSHvNXfzBAKzwj95x").collection(subCollection).document()
        let account = Account(amount: data.contentTextField, date: data.dateTime,
                              accountId: "vdH5py0HZ9ZP791pUFM8",
                              expenditureId: "GWiBqlywvYj12jEJkjkw", detail: data.detailTextView)
        do {
            try fetchDocumentID.setData(from: account)
            print("success create document. ID: \(fetchDocumentID.documentID)")
        } catch {
            print(error)
        }
    }
}

extension AddNewDataViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 把當前點到的indexPath傳到cell的indexPath
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
                    withIdentifier: "dateCell") as? AddDateTableViewCell
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

// MARK: - notice
                // 判斷目前在哪一個indexPath.row來決定要給cell的content哪一個array
                switch indexPath.row {
                default:
                    addDataCell.content = accountContent
                }

                // 每次切換segment時，讓顯示金額、種類、帳戶的textField重置（意指把picker先清除），因為在生成cell時會在傳indexPath過去cell時給予對應的picker
                addDataCell.contentTextField.inputView = nil
                addDataCell.indexPath = indexPath
                addDataCell.segmentTag = segmentTag
                addDataCell.delegate = self
                // 依照category array裡的資料筆數決定section:1有幾個cell
                addDataCell.fillInContent(name: transferCategory[indexPath.row])
                addDataCell.contentTextField.textAlignment = .center
                addDataCell.contentConfig(segment: segmentTag)
                return addDataCell
            } else if indexPath.section == 2 {
                guard let qrCell = tableView.dequeueReusableCell(
                    withIdentifier: "QRCell") as? QRCodeTableViewCell
                else {
                    fatalError("can not create cell")
                }
    //            qrCell.qrButton.setImage(UIImage(systemName: "qrcode.viewfinde"), for: .normal)
                return qrCell
            } else {
                guard let detailCell = tableView.dequeueReusableCell(
                    withIdentifier: "detailCell") as? DetailTableViewCell
                else {
                    fatalError("can not create cell")
                }
                detailCell.detailTextView.text = ""
                detailCell.delegate = self
                return detailCell
            }
        } else {
            if indexPath.section == 0 {
                guard let dateCell = tableView.dequeueReusableCell(
                    withIdentifier: "dateCell") as? AddDateTableViewCell
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

// MARK: - notice
                // 判斷目前在哪一個indexPath.row來決定要給cell的content哪一個array
                switch indexPath.row {
                case 1:
                    addDataCell.content = costContent
                default:
                    addDataCell.content = accountContent
                }

                // 每次切換segment時，讓顯示金額、種類、帳戶的textField重置（意指把picker先清除），因為在生成cell時會在傳indexPath過去cell時給予對應的picker
                addDataCell.contentTextField.inputView = nil
                addDataCell.indexPath = indexPath
                addDataCell.segmentTag = segmentTag
                addDataCell.delegate = self
                addDataCell.fillInContent(name: costCategory[indexPath.row])
                addDataCell.contentTextField.textAlignment = .center
                addDataCell.contentConfig(segment: segmentTag)
                return addDataCell
            } else if indexPath.section == 2 {
                guard let qrCell = tableView.dequeueReusableCell(
                    withIdentifier: "QRCell") as? QRCodeTableViewCell
                else {
                    fatalError("can not create cell")
                }
//            qrCell.qrButton.setImage(UIImage(systemName: "qrcode.viewfinde"), for: .normal)
                return qrCell
            } else {
                guard let detailCell = tableView.dequeueReusableCell(
                    withIdentifier: "detailCell") as? DetailTableViewCell
                else {
                    fatalError("can not create cell")
                }
                detailCell.detailTextView.text = ""
                detailCell.delegate = self
                return detailCell
            }
        }
    }
}

// date cell
extension AddNewDataViewController: AddDateTableViewCellDelegate {
    // 用delegate把cell和點選的sender傳過來，進行給新值的動作
    func getDate(_ cell: AddDateTableViewCell, sender: UIDatePicker) {
        // 當date picker改變時，執行此func，把當前改變的date塞給textfield
        cell.dateTextfield.text = formatter.string(from: sender.date)
        // date改用string型別存取，因為只需要存"年/月/日"，存時間"時/分"的話後續無法抓取資料
        data.dateTime = formatter.string(from: sender.date)
    }
}

// new data cell
extension AddNewDataViewController: AddNewDataTableViewCellDelegate {
    // 用delegate把alertVC要用到的present在這邊做，因為cell無法直接用present這個動作
    func addNewContent(_ cell: AddNewDataTableViewCell) {
        present(cell.controller, animated: true)
    }

    func getInputTextField(indexPath: IndexPath, textField: String) {
        self.tapIndexpath = indexPath
        data.contentTextField = textField
        print("======= \(data.contentTextField)")
    }

    func getTitle(indexPath: IndexPath, title: String) {
        self.tapIndexpath = indexPath
        data.titleLabel = title
        print("======= \(data.titleLabel)")
    }

    // 新增的選項用delegate傳回來並改變array data
    func setContent(content: [String]) {
        // 當轉帳頁面時，都會抓帳戶資訊
        switch segmentTag {
        case 2:
            accountContent = content
        // 其餘頁面-支出/收入
        default:
            if tapIndexpath?.item == 1 {
                costContent = content
            } else {
                accountContent = content
            }
        }
        // 當轉帳頁面時，都會抓帳戶資訊
//        switch segmentTag {
//        case 2:
//            data.latestElement = accountContent.last ?? ""
//        // 其餘頁面-支出/收入
//        default:
//            if tapIndexpath?.item == 1 {
//                data.latestElement = costContent.last ?? ""
//            } else {
//                data.latestElement = accountContent.last ?? ""
//            }
//        }
    }
}

// detail cell
extension AddNewDataViewController: DetailTableViewCellDelegate {
    func getDetail(detail: String) {
        data.detailTextView = detail
        print("======= this is detail \(data.detailTextView)")
    }
}
