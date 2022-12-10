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
    var monthTime: String = ""
    var titleLabel: String = ""
    var detailTextView: String = ""
    var categoryImageName: String = ""
    var segmentTag: Int = 0
}

class EditViewController: UIViewController {
    // 接homeVC點選對應cell的單筆資料，並存到editVC struct裡
    var data: Account? {
        didSet {
            editData.dateTime = data?.date ?? ""
            editData.monthTime = data?.month ?? ""
            editData.amountTextField = data?.amount ?? ""
            editData.categoryImageName = data?.categoryImage ?? ""
            editData.categoryTextField = data?.category ?? ""
            editData.accountTextField = data?.account ?? ""
            editData.detailTextView = data?.detail ?? ""
            editData.categoryImageName = data?.categoryImage ?? ""
            editData.segmentTag = data?.segmentTag ?? 0
        }
    }
    var category: [Category] = []
    var costCategory: [String] = ["金額", "種類", "帳戶"]
    var transferCategory: [String] = ["金額", "來源帳戶", "目的帳戶"]
    // 存支出textField picker資料
    var costContent: [String] = [] {
        didSet {
            editTableView.reloadData()
        }
    }
    // 存收入textField picker資料
    var incomeContent: [String] = [] {
        didSet {
            editTableView.reloadData()
        }
    }
    // 存轉帳textField picker資料
    var accountContent: [String] = [] {
        didSet {
            editTableView.reloadData()
        }
    }
    var costImageArr = [UIImage(named: "Breakfast"),
                        UIImage(named: "Lunch"),
                        UIImage(named: "Dinner"),
                        UIImage(named: "Drink"),
                        UIImage(named: "Medicine"),
                        UIImage(named: "Shopping"),
                        UIImage(named: "Snack"),
                        UIImage(named: "Entertainment"),
                        UIImage(named: "Transportation")]
    // 存income image的資料
    var incomeImageArr = [UIImage(named: "Bonus"),
                          UIImage(named: "Investments"),
                          UIImage(named: "Salary")]
    // 存account image的資料
    var accountImageArr = [UIImage(named: "Add-clicked"),
                           UIImage(named: "Add-unclicked")]
    var segmentTag = 0
    var tapIndexpath: IndexPath?
    var imageIndexPath: IndexPath?
    var editData = DataModel()
    weak var homeVC: ViewController?
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
    // alertController
    var controller = UIAlertController()

    @IBOutlet weak var editTableView: UITableView!
    @IBOutlet weak var sourceSegmentControl: UISegmentedControl!
    @IBAction func insertEditQRCode(_ sender: UIButton) {
        guard let presentEditQRScanVC = self.storyboard?.instantiateViewController(withIdentifier: "editQRScanVC") as? EditQRCodeViewController
        else {
            fatalError("can not find EditQRScanner VC")
        }
        presentEditQRScanVC.delegate = self
        self.present(presentEditQRScanVC, animated: true)
    }

// MARK: - TODO
    // 偵測第幾個segment control後直接在新VC上顯示對應index

    override func viewDidLoad() {
        super.viewDidLoad()
        getId = KeychainWrapper.standard.string(forKey: "id") ?? ""
        editTableView.delegate = self
        editTableView.dataSource = self

        // segmentControl 偵測改值狀態
        didSelectsegmentedControl()
        setupUI()
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

    // UI
    func setupUI() {
        // segmented control邊框
        sourceSegmentControl.layer.borderWidth = 1.5
        sourceSegmentControl.layer.borderColor = CGColor(red: 233/255, green: 229/255, blue: 218/255, alpha: 1)
        // 預設一進去segmented所選文字為黑色+黃底
        if sourceSegmentControl.selectedSegmentIndex == 0 {
            sourceSegmentControl.selectedSegmentTintColor = UIColor().hexStringToUIColor(hex: "E5BB4B")
            let segementTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            sourceSegmentControl.setTitleTextAttributes(segementTextAttributes, for: .normal)
        }
        editTableView.backgroundColor = UIColor().hexStringToUIColor(hex: "EBE5D9")
        // tableView top內縮10 points
        editTableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        view.backgroundColor = UIColor().hexStringToUIColor(hex: "1b4464")
    }

    // segmentControl 偵測改值狀態
    func didSelectsegmentedControl() {
        sourceSegmentControl.addTarget(self, action: #selector(handleSegmentControl), for: .valueChanged)
    }

    // func for segmentControl 更改時切換頁面
    @objc func handleSegmentControl() {
        // 設置segmented control被選取時文字、button顏色
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        sourceSegmentControl.setTitleTextAttributes(titleTextAttributes, for: .selected)

        // 設置對應segmentTag顏色
        segmentTag = sourceSegmentControl.selectedSegmentIndex
        switch segmentTag {
        case 1:
            sourceSegmentControl.selectedSegmentTintColor =  UIColor().hexStringToUIColor(hex: "92c7bd")
        case 2:
            sourceSegmentControl.selectedSegmentTintColor = .systemBrown
        default:
            sourceSegmentControl.selectedSegmentTintColor = UIColor().hexStringToUIColor(hex: "E5BB4B")
        }
        guard let cell = editTableView.cellForRow(at: IndexPath(row: 1, section: 1)) as? EditDataTableViewCell else { fatalError("can not specific cell") }
        cell.resetContent()
        editData.categoryTextField = ""
        editData.categoryImageName = ""
        editTableView.reloadData()
    }

    // 取消新增資料按鈕trigger
    func cancelNewData() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Cancel"), style: .plain, target: self, action: #selector(dismissPage))
    }

    // 取消並dismiss VC
    @objc func dismissPage() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    // 儲存已編輯完成的data
    func saveEditData() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Pencil_original"), style: .plain, target: self, action: #selector(saveEdit))
    }

    // 儲存並dismiss VC
    @objc func saveEdit() {
        if editData.amountTextField == "" {
            noAmountAlert()
            return
        }
        // 編輯(updateDocument)firebase上的data
        self.editAllUser()
    }

    // 判斷指定資料原先是哪個大類別
    func dataSegmentCategory() -> String {
        switch editData.segmentTag {
        case 0:
            return "expenditure"
        case 1:
            return "revenue"
        default:
            return "account"
        }
    }

    // 判斷有修改的動作後最終切換到哪個大類別
    func segmentCategory() -> String {
        switch segmentTag {
        case 0:
            return "expenditure"
        case 1:
            return "revenue"
        default:
            return "account"
        }
    }

    // 當金額為空值時，跳出警告訊息
    func noAmountAlert() {
        // 掃描時跳出alert提醒使用者掃描左邊QRCode
        controller = UIAlertController(title: "金額不得為空", message: "請輸入金額", preferredStyle: .alert)
        // 建立[我知道了]按鈕
        let okAction = UIAlertAction(
            title: "我知道了",
            style: .default, handler: nil)
        controller.addAction(okAction)
        // 顯示提示框
        self.present(controller, animated: true, completion: nil)
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

    // 針對更改的單筆資料，若原先為revenue修改為expenditure，則將subCollection revenue的document刪除，並新增一筆document到subCollection expenditure
    func editAllUser() {
        if editData.segmentTag != segmentTag {
            BBCoFireBaseManager.shared.deleteSpecificData(id: getId, subCollection: dataSegmentCategory(), dataId: data?.id ?? "")
            BBCoFireBaseManager.shared.editUserData(tableView: editTableView, id: getId, subCollection: segmentCategory(), amount: editData.amountTextField, category: editData.categoryTextField, account: editData.accountTextField, month: editData.monthTime, detail: editData.detailTextView, categoryImage: editData.categoryImageName, segment: segmentTag)
        }
        BBCoFireBaseManager.shared.editUserDetail(tableView: editTableView, id: getId, subCollection: dataSegmentCategory(), documentID: data?.id ?? "", amount: editData.amountTextField, category: editData.categoryTextField, account: editData.accountTextField, detail: editData.detailTextView, category_image: editData.categoryImageName)
        // notify放這邊是因為要等所有edit API執行完後再執行dismiss VC
        group.notify(queue: .main) {
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }

    // 掃描QRCode error handle
    func parseErrorAlert() {
        self.controller = UIAlertController(title: "Oops, 系統有點問題，請再試一次", message: nil, preferredStyle: .alert)
        
        let okAction = UIAlertAction(
            title: "再試一次",
            style: .default) { action in
                guard let presentEditQRScanVC = self.storyboard?.instantiateViewController(withIdentifier: "editQRScanVC") as? EditQRCodeViewController else {
                    fatalError("can not find presentEditQRScan VC")
                }
                presentEditQRScanVC.delegate = self
                self.present(presentEditQRScanVC, animated: true)
            }
        self.controller.addAction(okAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        self.controller.addAction(cancelAction)
        // 顯示提示框
        self.present(self.controller, animated: true, completion: nil)
    }

    // 解析invoice data
    func decodeInvoice(message: String) {
        let invNum = message.prefix(10)
        let encrypt = message.prefix(24)
        var invYear = (message as NSString).substring(with: NSMakeRange(10, 3))
        var translateYear = (Int(invYear) ?? 0) + 1911
        invYear = String(translateYear)

        let invMonth = (message as NSString).substring(with: NSMakeRange(13, 2))
        let invDay = (message as NSString).substring(with: NSMakeRange(15, 2))
        let randomNumber = (message as NSString).substring(with: NSMakeRange(17, 4))
        let sellerID = (message as NSString).substring(with: NSMakeRange(45, 8))

        // POST API
        sendInvoiceAPI(invNum: String(invNum), invDate: "\(invYear)/\(invMonth)/\(invDay)", encrypt: String(encrypt), sellerID: sellerID, randomNumber: randomNumber)

        // 確認是否有取到正確資料
        print("invNum \(invNum), message \(message), encrypt \(encrypt), invYear \(invYear), invMonth \(invMonth), invDay \(invDay), randomNumber \(randomNumber), sellerID \(sellerID)")
    }

    // POST API and parse data
    func sendInvoiceAPI(invNum: String, invDate: String, encrypt: String, sellerID: String, randomNumber: String) {
        let url = URL(string: "https://api.einvoice.nat.gov.tw/PB2CAPIVAN/invapp/InvApp?version=0.6&type=QRCode&invNum=\(invNum)&action=qryInvDetail&generation=V2&invDate=\(invDate)&encrypt=\(encrypt)&sellerID=\(sellerID)&UUID=\(APIKey.invoiceUUID)&randomNumber=\(randomNumber)&appID=\(APIKey.QRAppID)")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request, completionHandler: {(data, response, error) in
            if let error = error {
                print("=== post API is error", error)
                DispatchQueue.main.async {
                    self.parseErrorAlert()
                }
                return
            }

            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200 else {
                print("response error")
                return
            }

            if let dataInv = data, let detail = self.parseData(jsonData: dataInv) {
                self.calculateAmountAndCategory(detail: detail)
            }
        })
        task.resume()
    }

    func parseData(jsonData: Data) -> Invoice? {
        do {
            let result = try JSONDecoder().decode(Invoice.self, from: jsonData)
            // 測試看是否有抓到資料
            print("=== result is \(jsonData)")
            return result
        }catch {
            print("result error")
            return nil
        }
    }

    // 計算invoice data總金額 & 細項總和
    func calculateAmountAndCategory(detail: Invoice) {
        // 讓掃描完的amount & detail data自動傳進textField，不需觸發到textFieldDidEndEditing
        self.editData.detailTextView = ""
        var amount = 0
        for item in 0..<detail.details.count {
            amount += (Int(detail.details[item].amount) ?? 0)
            self.editData.detailTextView +=  "\(detail.details[item].detailDescription)\n"
        }
        self.editData.amountTextField = String(amount)
        // 拿到decode data後要更新畫面上的textField，屬於UI設定，故要切回main thread做
        DispatchQueue.main.async {
            self.editTableView.reloadData()
        }
    }
}

extension EditViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
//        case 1:
//            return 1
        case 1:
            return costCategory.count
        case 2:
            if segmentTag == 2 {
                return 0
            } else {
                return 1
            }
        default:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "選擇日期"
//        case 1:
//            return "選擇圖案"
        case 1:
            return "選擇細項"
        case 2:
            if segmentTag == 2 {
                return nil
            } else {
                return "使用QRCode掃描發票"
            }
        default:
            return "備註"
        }
    }
    
//    enum Section: Int {
//        case amount = 0
//        case catrgory = 1
//        case qrCode = 2
//        case detail = 3
//    }

// MARK: - 轉帳segemant
    // swiftlint:disable cyclomatic_complexity
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard var section = Section(rawValue: indexPath.row) else {
//            fatalError("can not upwrapped section")
//        }
        
        if segmentTag == 2 {
            if indexPath.section == 0 {
                guard let editTimeCell = tableView.dequeueReusableCell(
                    withIdentifier: "editTimeCell") as? EditTimeTableViewCell
                else {
                    fatalError("can not create cell")
                }
                editTimeCell.setDate(dateTime: editData.dateTime)
                return editTimeCell
            } else if indexPath.section == 1 {
                guard let editDataCell = tableView.dequeueReusableCell(withIdentifier: "editDataCell") as? EditDataTableViewCell else {
                    fatalError("can not create cell")
                }
                editDataCell.delegate = self
                // 配置pickerView & titleName
                editDataCell.contentConfig(segment: segmentTag, indexPath: indexPath, titleName: transferCategory[indexPath.row])
                // 判斷目前在哪一個indexPath.row來決定要給cell的content哪一個array
                switch indexPath.row {
                case 0:
                    editDataCell.setContentAndImage(contentPickerView: nil, imagePickerView: nil, content: editData.amountTextField, image: nil, segmentTag: segmentTag)
                case 1:
                    editDataCell.setContentAndImage(contentPickerView: accountContent, imagePickerView: accountImageArr, content: editData.categoryTextField, image: editData.categoryImageName.toImage(), segmentTag: segmentTag)
                default:
                    editDataCell.setContentAndImage(contentPickerView: accountContent, imagePickerView: nil, content: editData.accountTextField, image: nil, segmentTag: segmentTag)
                }
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
                editDetailCell.delegate = self
                editDetailCell.config(detailText: editData.detailTextView)
                return editDetailCell
            }
// MARK: - 支出、收入segemant
        } else {
            if indexPath.section == 0 {
                guard let editTimeCell = tableView.dequeueReusableCell(
                    withIdentifier: "editTimeCell") as? EditTimeTableViewCell
                else {
                    fatalError("can not create cell")
                }
                editTimeCell.setDate(dateTime: editData.dateTime)
                return editTimeCell
            } else if indexPath.section == 1 {
                guard let editDataCell = tableView.dequeueReusableCell(withIdentifier: "editDataCell") as? EditDataTableViewCell else {
                    fatalError("can not create cell")
                }
                editDataCell.delegate = self
                editDataCell.contentConfig(segment: segmentTag, indexPath: indexPath, titleName: costCategory[indexPath.row])
                // 判斷目前在哪一個indexPath.row來決定要給cell的content哪一個array
                switch indexPath.row {
                case 0:
                    editDataCell.setContentAndImage(contentPickerView: nil, imagePickerView: nil, content: editData.amountTextField, image: nil, segmentTag: segmentTag)
                case 1:
                    switch segmentTag {
                    case 0:
                        editDataCell.setContentAndImage(contentPickerView: costContent, imagePickerView: costImageArr, content: editData.categoryTextField, image: editData.categoryImageName.toImage(), segmentTag: segmentTag)
                    default:
                        editDataCell.setContentAndImage(contentPickerView: incomeContent, imagePickerView: incomeImageArr, content: editData.categoryTextField, image: editData.categoryImageName.toImage(), segmentTag: segmentTag)
                    }
                default:
                    editDataCell.setContentAndImage(contentPickerView: accountContent, imagePickerView: nil, content: editData.accountTextField, image: nil, segmentTag: segmentTag)
                }
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
                editDetailCell.delegate = self
                editDetailCell.config(detailText: editData.detailTextView)
                return editDetailCell
            }
        }
    }
}

// new data cell
extension EditViewController: EditDataTableViewCellDelegate {
    // 用delegate把alertVC要用到的present在這邊做，因為cell無法直接用present這個動作
    func addNewContent(_ cell: EditDataTableViewCell, indexPathItem: Int) {
        if indexPathItem == 0 {
            present(cell.presentCalculateVC ?? UIViewController(), animated: true)
        } else {
            present(cell.controller, animated: true)
        }
    }

    func getInputTextField(indexPath: IndexPath, textField: String) {
        self.tapIndexpath = indexPath
        switch tapIndexpath?.row {
        case 0:
            editData.amountTextField = textField
        case 1:
            editData.categoryTextField = textField
        default:
            editData.accountTextField = textField
        }
    }

    func getTitle(indexPath: IndexPath, title: String) {
        self.tapIndexpath = indexPath
        editData.titleLabel = title
    }

    // 新增的選項用delegate傳回來並改變array data
    func setContent(indexPathItem: Int, content: [String]) {
        // 當轉帳頁面時，都會抓帳戶資訊
        switch segmentTag {
        // 頁面-支出
        case 0:
            if indexPathItem == 1 {
                costContent = content
            } else {
                accountContent = content
            }
        // 頁面-收入
        case 1:
            if indexPathItem == 1 {
                incomeContent = content
            } else {
                accountContent = content
            }
        // 頁面-轉帳
        default:
            accountContent = content
        }
    }

    func getImageName(indexPath: IndexPath, imageName: String) {
        self.imageIndexPath = indexPath
        switch imageIndexPath?.row {
        case 1:
            editData.categoryImageName = imageName
        default:
            return
        }
    }
}

// detail cell
extension EditViewController: EditDetailTableViewCellDelegate {
    func getDetail(detail: String) {
        editData.detailTextView = detail
    }
}

// QRCode text from QRCodeVC
extension EditViewController: EditQRCodeViewControllerDelegate {
    func getMessage(message: String) {
        // 解析發票亂碼
        self.decodeInvoice(message: message)
    }
}
