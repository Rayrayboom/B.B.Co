//
//  EditViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/3.
//

import UIKit
import SwiftUI
import AVFoundation
import Vision
import VisionKit
import FirebaseFirestore
import SwiftKeychainWrapper

struct DataModel {
    var amountTextField: String = ""
    var categoryTextField: String = ""
    var accountTextField: String = ""

    // date改用string型別存取，因為只需要存"年/月/日"，存時間"時/分"的話後續無法抓取資料
    var dateTime: String = ""
    var titleLabel: String = ""
    var detailTextView: String = ""
}

class EditViewController: UIViewController {
    var data: Account?
    var category: [Category] = []
    var costCategory: [String] = ["金額", "種類", "帳戶"]
    var transferCategory: [String] = ["金額", "來源帳戶", "目的帳戶"]
    // 存支出textField picker資料
    var costContent: [String] = [] {
        didSet {
            print("=== this is all costContent \(self.costContent)")
            editTableView.reloadData()
        }
    }
    // 存收入textField picker資料
    var incomeContent: [String] = [] {
        didSet {
            print("=== this is all incomeContent \(self.incomeContent)")
            editTableView.reloadData()
        }
    }
    // 存轉帳textField picker資料
    var accountContent: [String] = [] {
        didSet {
            print("=== this is all accountContent \(self.accountContent)")
            editTableView.reloadData()
        }
    }
    var segmentTag = 0
    var tapIndexpath: IndexPath?
    var editData = DataModel()
    weak var homeVC: ViewController?
    // 用來判斷是否有使用QR scanner去掃描內容
    var isTappedQR = 0
    // 存QRCode掃描內容
    var messageFromQRVC: String = "" {
        didSet {
            editTableView.reloadData()
        }
    }
    // 存decode後的發票資料
    var invoice: Invoice? {
        didSet {
            DispatchQueue.main.async {
                self.editTableView.reloadData()
            }
        }
    }
    var items: String = ""

    var content: String = "" {
        didSet {
            editTableView.reloadData()
        }
    }
    var getId: String = ""

    let group = DispatchGroup()
    let queueGroup = DispatchQueue.global()

    @IBOutlet weak var editTableView: UITableView!
    @IBOutlet weak var sourceSegmentControl: UISegmentedControl!
    @IBAction func insertEditQRCode(_ sender: UIButton) {
        guard let presentEditQRScanVC = self.storyboard?.instantiateViewController(withIdentifier: "editQRScanVC") as? EditQRCodeViewController
        else {
            fatalError("can not find EditQRScanner VC")
        }
        // 當內容是透過QR scanner拿取，isTappedQR == 1
        isTappedQR = 1
        presentEditQRScanVC.delegate = self
        present(presentEditQRScanVC, animated: true)
    }

// MARK: - TODO
    // 偵測第幾個segment control後直接在新VC上顯示對應index

    override func viewDidLoad() {
        super.viewDidLoad()
        getId = KeychainWrapper.standard.string(forKey: "id") ?? ""
        editTableView.delegate = self
        editTableView.dataSource = self

        // segmentControl 偵測改值狀態
        sourceSegmentControl.addTarget(self, action: #selector(handelSegmentControl), for: .valueChanged)
        // 點選X時，執行取消新增
        cancelNewData()
        // 點選pencil時，執行更新編輯
        saveEditData()
        // 抓firebase上的支出/收入/轉帳的種類/帳戶pickerView選項資料
        fetchUser(id: getId, subCollection: "expenditure")
        fetchUser(id: getId, subCollection: "revenue")
        fetchUser(id: getId, subCollection: "account")
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
        editTableView.reloadData()
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

    // 儲存已編輯完成的data
    func saveEditData() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "pencil"), style: .plain, target: self, action: #selector(saveEdit))
    }

// MARK: -如下edit func先全部執行，目前可以照預期的呈現，後續再來想判斷式
    // 儲存並dismiss VC
    @objc func saveEdit() {
        // 按下儲存編輯時isTappedQR要重置，才不會影響下一筆編輯的資料判斷
        isTappedQR = 0
        // 編輯(updateDocument)firebase上的data
        self.editAllUser()
    }

    // 從Firebase上fetch全部種類/帳戶資料
    func fetchUser(id: String, subCollection: String) {
        let dataBase = Firestore.firestore()
        dataBase.collection("user/\(id)/\(subCollection)_category")
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

    // 點選對應細項編輯資料
    func editUser(id: String, subCollection: String, documentID: String) {
        let dataBase = Firestore.firestore()
        // 因為有API抓取時間差GCD問題，故用group/notice來讓API資料全部回來後再同步更新到tableView上
        // 進入group
        self.group.enter()
        dataBase.collection("user/\(id)/\(subCollection)").document("\(documentID)").updateData([
            "date": editData.dateTime,
            "amount": editData.amountTextField,
            "category": editData.categoryTextField,
            "account": editData.accountTextField,
            "detail": editData.detailTextView
        ]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document update successfully ")
            }
            // 每一支API打完之後leave group
            self.group.leave()
        }
    }

    func editAllUser() {
        editUser(id: getId, subCollection: "expenditure", documentID: data?.id ?? "")
        editUser(id: getId, subCollection: "revenue", documentID: data?.id ?? "")
        editUser(id: getId, subCollection: "account", documentID: data?.id ?? "")

        // notify放這邊是因為要等所有edit API執行完後再執行dismiss VC
        group.notify(queue: .main) {
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
}

extension EditViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
        // 點擊cell時收起鍵盤
        view.endEditing(true)
    }
}

extension EditViewController: UITableViewDataSource {
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
        switch section {
        case 0:
            return 1
        case 1:
            return costCategory.count
        case 2:
            return 1
        default:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let editTimeCell = tableView.dequeueReusableCell(
                withIdentifier: "editTimeCell") as? EditTimeTableViewCell
            else {
                fatalError("can not create cell")
            }

            // 設定datePicker的delegate
            editTimeCell.delegate = self
            let date = Date()
            // formatter把日期(date)轉成String塞給dateStr
            let dateStr = BBCDateFormatter.shareFormatter.string(from: date)
            // 把存著date的dateStr用cell的func config()塞值給cell裡面的textField
            editTimeCell.config(dateStr: dateStr)
            // 在生成editDataCell時先把已經從firebase抓下來的單筆對應資料的值塞給struct(editData)
            editData.dateTime = self.data?.date ?? ""
            // 接著把已經從firebase抓下來的單筆對應資料的值塞給editVC中的dateTextField.text顯示
            editTimeCell.dateTextfield.text = self.data?.date ?? ""
            return editTimeCell
        } else if indexPath.section == 1 {
            guard let editDataCell = tableView.dequeueReusableCell(withIdentifier: "editDataCell") as? EditDataTableViewCell else {
                fatalError("can not create cell")
            }
// MARK: - notice
            // 判斷目前在哪一個indexPath.row來決定要給cell的content哪一個array
            switch indexPath.row {
            case 0:
                // 判斷-當QRCode還沒進行掃描時messageFromQRVC會為空string""，用nil的話會一直成立
                if messageFromQRVC != "" {
                    var amo = 0
                    for num in 0..<(invoice?.details.count ?? 0) {
                        amo = (amo + (Int(invoice?.details[num].amount ?? "") ?? 0))
                    }
                    editDataCell.contentTextField.text = String(amo)
                    print("aaaaaa", amo)
                } else {
                    editData.amountTextField = self.data?.amount ?? ""
                    editDataCell.contentTextField.text = self.data?.amount
                }
            case 1:
                switch segmentTag {
                case 0:
                    editDataCell.content = costContent
                    // 在生成editDataCell時先把已經從firebase抓下來的單筆對應資料的值塞給struct(editData)
                    editData.categoryTextField = self.data?.category ?? ""
                    // 接著把已經從firebase抓下來的單筆對應資料的值塞給editVC中的textField.text顯示
                    editDataCell.contentTextField.text = self.data?.category
                case 1:
                    editDataCell.content = incomeContent
                    editData.categoryTextField = self.data?.category ?? ""
                    editDataCell.contentTextField.text = self.data?.category
                default:
                    editDataCell.content = accountContent
                    editData.accountTextField = self.data?.account ?? ""
                    editDataCell.contentTextField.text = self.data?.account
                }
            default:
                editDataCell.content = accountContent
                editData.accountTextField = self.data?.account ?? ""
                editDataCell.contentTextField.text = self.data?.account
            }

            // 測試從homeVC抓到傳過來的資料
//            print("datadatadatadatadata\(self.data)")
            // 每次切換segment時，讓顯示金額、種類、帳戶的textField重置（意指把picker先清除），因為在生成cell時會在傳indexPath過去cell時給予對應的picker
            editDataCell.contentTextField.inputView = nil
            editDataCell.indexPath = indexPath
            editDataCell.segmentTag = segmentTag
            editDataCell.delegate = self
            editDataCell.fillInContent(name: costCategory[indexPath.row])
            editDataCell.contentTextField.textAlignment = .center
            editDataCell.contentConfig(segment: segmentTag)
            return editDataCell
        } else if indexPath.section == 2 {
            guard let editQRCell = tableView.dequeueReusableCell(
                withIdentifier: "editQRCell") as? EditQRCodeTableViewCell
            else {
                fatalError("can not create cell")
            }
            return editQRCell
        } else {
            guard let editDetailCell = tableView.dequeueReusableCell(
                withIdentifier: "editDetailCell") as? EditDetailTableViewCell
            else {
                fatalError("can not create cell")
            }
            editData.detailTextView = self.data?.detail ?? ""
            // 判斷：當內容是透過QR scanner拿取(isTappedQR == 1)的話，則顯示對應掃描資訊; 若是一班手動編輯(isTappedQR == 0)則顯示原textView資訊
            if isTappedQR == 1 {
                // 存放invoice的string在fetch data之前要先清空
                items = ""
                // 把message的值塞給detailTextView
                for item in 0..<(invoice?.details.count ?? 0) {
                    guard let invoice = invoice else {
                        fatalError("pass invDetail data error")
                    }
                    items.append("\(invoice.details[item].detailDescription)\n")
                    editDetailCell.detailTextView.text = items
                }
                // 把message的值塞給detailTextView
//                editDetailCell.detailTextView.text = messageFromQRVC
            } else {
                editDetailCell.detailTextView.text = self.data?.detail
            }
            editDetailCell.delegate = self
            return editDetailCell
        }
    }
}

// date cell
extension EditViewController: EditTimeTableViewCellDelegate {
    // 用delegate把cell和點選的sender傳過來，進行給新值的動作
    func getDate(_ cell: EditTimeTableViewCell, sender: UIDatePicker, textField: String) {
        // 當date picker改變時，執行此func，把當前改變的date塞給textfield
        cell.dateTextfield.text = BBCDateFormatter.shareFormatter.string(from: sender.date)
        // date改用string型別存取，因為只需要存"年/月/日"，存時間"時/分"的話後續無法抓取資料
        editData.dateTime = BBCDateFormatter.shareFormatter.string(from: sender.date)
    }
}

// new data cell
extension EditViewController: EditDataTableViewCellDelegate {
    // 用delegate把alertVC要用到的present在這邊做，因為cell無法直接用present這個動作
    func addNewContent(_ cell: EditDataTableViewCell) {
        present(cell.controller, animated: true)
    }

    func getInputTextField(indexPath: IndexPath, textField: String) {
        self.tapIndexpath = indexPath
        switch tapIndexpath?.row {
        case 0:
            editData.amountTextField = textField
            print("======= \(editData.amountTextField)")
        case 1:
            editData.categoryTextField = textField
            print("======= \(editData.categoryTextField)")
        default:
            editData.accountTextField = textField
            print("======= \(editData.accountTextField)")
        }
    }

    func getTitle(indexPath: IndexPath, title: String) {
        self.tapIndexpath = indexPath
        editData.titleLabel = title
        print("======= \(editData.titleLabel)")
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
extension EditViewController: EditDetailTableViewCellDelegate {
    func getDetail(detail: String) {
        editData.detailTextView = detail
        print("======= this is detail \(editData.detailTextView)")
    }
}

// QRCode text from QRCodeVC
extension EditViewController: EditQRCodeViewControllerDelegate {
    func getMessage(message: String) {
        print("wwwww??")
        messageFromQRVC = message
    }

    func getInvDetail(didGet items: Invoice) {
        invoice = items
    }

    func getInvDetail(didFailwith error: Error) {
        print("can not parse invoice data")
    }
}
