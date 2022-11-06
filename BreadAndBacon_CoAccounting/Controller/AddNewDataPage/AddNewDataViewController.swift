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
    var amountTextField: String = ""
    var categoryTextField: String = ""
    var accountTextField: String = ""

    // date改用string型別存取，因為只需要存"年/月/日"，存時間"時/分"的話後續無法抓取資料
    var dateTime: String = ""
    var titleLabel: String = ""
    var detailTextView: String = ""
//    var latestElement: String = ""
}

class AddNewDataViewController: UIViewController, VNDocumentCameraViewControllerDelegate {
    var costCategory: [String] = ["金額", "種類", "帳戶"]
    var transferCategory: [String] = ["金額", "來源帳戶", "目的帳戶"]
    // 存支出textField picker資料
    var costContent: [String] = [] {
        didSet {
            print("=== this is all costContent \(self.costContent)")
            addNewDadaTableView.reloadData()
        }
    }
    // 存收入textField picker資料
    var incomeContent: [String] = [] {
        didSet {
            print("=== this is all incomeContent \(self.incomeContent)")
            addNewDadaTableView.reloadData()
        }
    }
    // 存轉帳textField picker資料
    var accountContent: [String] = [] {
        didSet {
            print("=== this is all accountContent \(self.accountContent)")
            addNewDadaTableView.reloadData()
        }
    }
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
        // 抓firebase上的支出/收入/轉帳的種類/帳戶pickerView選項資料
        fetchUser(subCollection: "expenditure")
        fetchUser(subCollection: "revenue")
        fetchUser(subCollection: "account")
        // datePicker的格式
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(savePage))
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

    // MARK: - 上傳資料到Firebase
    func createUserData(subCollection: String) {
        let dataBase = Firestore.firestore()
        let fetchDocumentID = dataBase.collection("user")
            .document("vy4oSHvNXfzBAKzwj95x")
            .collection(subCollection)
            .document()
        // 讓swift code先去生成一組id並存起來，後續要識別document修改資料用
        let identifier = fetchDocumentID.documentID
        // 需存id，後續delete要抓取ID刪除對應資料
        switch subCollection {
        case "expenditure":
            let account = Account(
                id: identifier,
                amount: data.amountTextField,
                category: data.categoryTextField,
                account: data.accountTextField,
                date: data.dateTime,
                destinationAccountId: nil,
                sourceAccountId: nil,
                accountId: "accountId",
                expenditureId: "expenditureId",
                revenueId: nil,
                detail: data.detailTextView)
            do {
                try fetchDocumentID.setData(from: account)
                print("success create document. ID: \(fetchDocumentID.documentID)")
            } catch {
                print(error)
            }
        case "revenue":
            let account = Account(
                id: identifier,
                amount: data.amountTextField,
                category: data.categoryTextField,
                account: data.accountTextField,
                date: data.dateTime,
                destinationAccountId: nil,
                sourceAccountId: nil,
                accountId: "accountId",
                expenditureId: nil,
                revenueId: "revenueId",
                detail: data.detailTextView)
            do {
                try fetchDocumentID.setData(from: account)
                print("success create document. ID: \(fetchDocumentID.documentID)")
            } catch {
                print(error)
            }
        default:
            let account = Account(
                id: identifier,
                amount: data.amountTextField,
                category: data.categoryTextField,
                account: data.accountTextField,
                date: data.dateTime,
                destinationAccountId: "destinationAccountId",
                sourceAccountId: "sourceAccountId",
                accountId: nil,
                expenditureId: nil,
                revenueId: nil,
                detail: data.detailTextView)
            do {
                try fetchDocumentID.setData(from: account)
                print("success create document. ID: \(fetchDocumentID.documentID)")
            } catch {
                print(error)
            }
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

                for num in 0..<category.count {
                    switch subCollection {
                    case "expenditure":
                        self.costContent.append(category[num].title)
                    case "revenue":
                        self.incomeContent.append(category[num].title)
                    default:
                        self.accountContent.append(category[num].title)
                    }
                }
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
                let dateStr = BBCDateFormatter.shareFormatter.string(from: date)
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
                    switch segmentTag {
                    case 0:
                        addDataCell.content = costContent
                    case 1:
                        addDataCell.content = incomeContent
                    default:
                        addDataCell.content = accountContent
                    }

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
                let dateStr = BBCDateFormatter.shareFormatter.string(from: date)
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
                    switch segmentTag {
                    case 0:
                        addDataCell.content = costContent
                    case 1:
                        addDataCell.content = incomeContent
                    default:
                        addDataCell.content = accountContent
                    }
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
        cell.dateTextfield.text = BBCDateFormatter.shareFormatter.string(from: sender.date)
        // date改用string型別存取，因為只需要存"年/月/日"，存時間"時/分"的話後續無法抓取資料
        data.dateTime = BBCDateFormatter.shareFormatter.string(from: sender.date)
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
        switch tapIndexpath?.row {
        case 0:
            data.amountTextField = textField
            print("======= \(data.amountTextField)")
        case 1:
            data.categoryTextField = textField
            print("======= \(data.categoryTextField)")
        default:
            data.accountTextField = textField
            print("======= \(data.accountTextField)")
        }
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
        // 頁面-支出
        case 0:
            if tapIndexpath?.item == 1 {
                costContent = content
            } else {
                accountContent = content
            }
        // 頁面-收入
        case 1:
            if tapIndexpath?.item == 1 {
                incomeContent = content
            } else {
                accountContent = content
            }
        // 頁面-轉帳
        default:
            accountContent = content
        }
    }
}

// detail cell
extension AddNewDataViewController: DetailTableViewCellDelegate {
    func getDetail(detail: String) {
        data.detailTextView = detail
        print("======= this is detail \(data.detailTextView)")
    }
}
