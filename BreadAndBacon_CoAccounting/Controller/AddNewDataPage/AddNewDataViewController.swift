//
//  AddNewDataViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/30.
//

import UIKit
import SwiftUI
import AVFoundation
import FirebaseFirestore
import SwiftKeychainWrapper
import SPAlert

// MARK: - expenditure
struct NewDataModel {
    var amountTextField: String = ""
    var categoryTextField: String = ""
    var accountTextField: String = ""

    // date改用string型別存取，因為只需要存"年/月/日"，存時間"時/分"的話後續無法抓取資料
    var dateTime: String = ""
    var monthTime: String = ""
    var titleLabel: String = ""
    var detailTextView: String = ""
    var categoryImageName: String = ""
}

struct Model {
    let text: String
    let imageName: String

    init(text: String, imageName: String) {
        self.text = text
        self.imageName = imageName
    }
}

class AddNewDataViewController: UIViewController {
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
    // 存cost image的資料
    var costImageArr = [UIImage(named: "Breakfast"),
                        UIImage(named: "Lunch"),
                        UIImage(named: "Lunch 2"),
                        UIImage(named: "Dinner")]
    // 存income image的資料
    var incomeImageArr = [UIImage(named: "Entertainment"),
                          UIImage(named: "Transportation")]
    // 存account image的資料
    var accountImageArr = [UIImage(named: "Add-clicked"),
                           UIImage(named: "Add-unclicked")]
    var segmentTag = 0
    var tapIndexpath: IndexPath?
    var imageIndexPath: IndexPath?
    var data = NewDataModel()
    var models = [Model]()
    var dateFromHomeVC: String? = ""
    // 存QRCode掃描內容
    var messageFromQRVC: String = "" {
        didSet {
            addNewDadaTableView.reloadData()
        }
    }
    // 存decode後的發票資料
    var invoice: Invoice? {
        didSet {
            DispatchQueue.main.async {
                self.addNewDadaTableView.reloadData()
            }
        }
    }
    var items: String = ""

    // for QRCode func use
    var content: String = "" {
        didSet {
            addNewDadaTableView.reloadData()
        }
    }
    // 儲存user id到keyChain
    var getId: String = ""

    @IBOutlet weak var addNewDadaTableView: UITableView!

    @IBOutlet weak var sourceSegmentControl: UISegmentedControl!

    @IBAction func insertQRCode(_ sender: UIButton) {
        guard let presentQRScanVC = self.storyboard?.instantiateViewController(withIdentifier: "qrScanVC") as? QRCodeViewController else {
            fatalError("can not find QRScanner VC")
        }
        presentQRScanVC.delegate = self
        present(presentQRScanVC, animated: true)
    }

// MARK: - TODO: 月曆優化（待處理）
//    @IBAction func presentCalendar(_ sender: UIButton) {
//        let addNewDataStoryboard: UIStoryboard = UIStoryboard(name: "AddNewData", bundle: nil)
//        guard let presentCalendarVC = addNewDataStoryboard.instantiateViewController(withIdentifier: "calendarVC") as? CalendarViewController else {
//            fatalError("can not present calendarVC")
//        }
//
//        presentCalendarVC.modalPresentationStyle = .currentContext
//        present(presentCalendarVC, animated: true)
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // 使用者登入後就可以抓到存在keyChain裡的user id
        getId = KeychainWrapper.standard.string(forKey: "id") ?? ""

        // 測試存images(暫時) for tableView with collectionView
        models.append(Model(text: "早餐", imageName: "Breakfast"))
        models.append(Model(text: "午餐", imageName: "Lunch"))
        models.append(Model(text: "午餐", imageName: "Lunch 2"))
        models.append(Model(text: "晚餐", imageName: "Dinner"))
        models.append(Model(text: "交通", imageName: "Transportation"))
        models.append(Model(text: "娛樂", imageName: "Entertainment"))
        models.append(Model(text: "早餐", imageName: "Breakfast"))
        models.append(Model(text: "午餐", imageName: "Lunch"))
        models.append(Model(text: "午餐", imageName: "Lunch 2"))
        models.append(Model(text: "晚餐", imageName: "Dinner"))
        models.append(Model(text: "交通", imageName: "Transportation"))
        models.append(Model(text: "娛樂", imageName: "Entertainment"))

        // 註冊image tableView cell
        addNewDadaTableView.register(ImageTableViewCell.nib(), forCellReuseIdentifier: ImageTableViewCell.identifier)
        addNewDadaTableView.delegate = self
        addNewDadaTableView.dataSource = self
        addNewDadaTableView.estimatedRowHeight = UITableView.automaticDimension

        // segmentControl 偵測改值狀態
        didSelectsegmentedControl()
        setupUI()
        // 點選X時，執行取消新增
        cancelNewData()
        // 點選+時，執行新增資料到firebase
        saveNewData()
        // 抓firebase上的支出/收入/轉帳的種類/帳戶pickerView選項資料
        fetchUserCategory(id: getId, subCollection: "expenditure")
        fetchUserCategory(id: getId, subCollection: "revenue")
        fetchUserCategory(id: getId, subCollection: "account")
        // datePicker的格式
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    func setupUI() {
        // segmented control邊框
        sourceSegmentControl.layer.borderWidth = 2.0
        sourceSegmentControl.layer.borderColor = UIColor.black.cgColor
        // 預設一進去segmented所選文字為白色+黃底
        if sourceSegmentControl.selectedSegmentIndex == 0 {
            sourceSegmentControl.selectedSegmentTintColor = UIColor.systemYellow
            let segementTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            sourceSegmentControl.setTitleTextAttributes(segementTextAttributes, for: .selected)
        }
        addNewDadaTableView.backgroundColor = UIColor(red: 245/255, green: 240/255, blue: 206/255, alpha: 1)
        view.backgroundColor = UIColor(red: 245/255, green: 240/255, blue: 206/255, alpha: 1)

// MARK: - TODO: 月曆優化（待處理）
//        let blackView = UIView(frame: UIScreen.main.bounds)
//        blackView.backgroundColor = .black
//        blackView.alpha = 0
//        presentingViewController?.view.addSubview(blackView)
//
//        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.5, delay: 0) {
//            blackView.alpha = 0.5
//        }
    }

    // segmentControl 偵測改值狀態
    func didSelectsegmentedControl() {
        sourceSegmentControl.addTarget(self, action: #selector(handelSegmentControl), for: .valueChanged)
    }

    // func for segmentControl 更改時切換頁面
    @objc func handelSegmentControl() {
        // 設置segmented control被選取時文字、button顏色
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        sourceSegmentControl.setTitleTextAttributes(titleTextAttributes, for: .selected)

        // 設置對應segmentTag顏色
        segmentTag = sourceSegmentControl.selectedSegmentIndex
        switch segmentTag {
        case 1:
            sourceSegmentControl.selectedSegmentTintColor = .systemCyan
        case 2:
            sourceSegmentControl.selectedSegmentTintColor = .systemBrown
        default:
            sourceSegmentControl.selectedSegmentTintColor = .systemYellow
        }
        // 切換segment control時，要先把textField和image的資料先清空，否則tableView會去抓前一筆資料的值
        data.amountTextField = ""
        data.categoryTextField = ""
        data.accountTextField = ""
        data.categoryImageName = ""
        addNewDadaTableView.reloadData()
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

    // 新增資料按鈕trigger
    func saveNewData() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Add_coData"), style: .plain, target: self, action: #selector(savePage))
    }

    // 新增並上傳firebase，用segmentTag來辨識要存到哪個document裡面
    @objc func savePage() {
        switch segmentTag {
        case 0:
            createUserData(id: getId, subCollection: "expenditure")
        case 1:
            createUserData(id: getId, subCollection: "revenue")
        default:
            createUserData(id: getId, subCollection: "account")
        }

        // success alert animation
        SPAlert.successAlert()

        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - 上傳資料到Firebase
    func createUserData(id: String, subCollection: String) {
        let dataBase = Firestore.firestore()
        let fetchDocumentID = dataBase.collection("user")
            .document(id)
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
                month: data.monthTime,
                destinationAccountId: nil,
                sourceAccountId: nil,
                accountId: "accountId",
                expenditureId: "expenditureId",
                revenueId: nil,
                detail: data.detailTextView,
                categoryImage: data.categoryImageName)
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
                month: data.monthTime,
                destinationAccountId: nil,
                sourceAccountId: nil,
                accountId: "accountId",
                expenditureId: nil,
                revenueId: "revenueId",
                detail: data.detailTextView,
                categoryImage: data.categoryImageName)
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
                month: data.monthTime,
                destinationAccountId: "destinationAccountId",
                sourceAccountId: "sourceAccountId",
                accountId: nil,
                expenditureId: nil,
                revenueId: nil,
                detail: data.detailTextView,
                categoryImage: data.categoryImageName)
            do {
                try fetchDocumentID.setData(from: account)
                print("success create document. ID: \(fetchDocumentID.documentID)")
            } catch {
                print(error)
            }
        }
    }
    // 從Firebase上fetch全部種類/帳戶資料
    func fetchUserCategory(id: String, subCollection: String) {
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
        if indexPath.section == 4 {
            return 250
        } else if indexPath.section == 1 {
            return 80
        } else {
            return UITableView.automaticDimension
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        case 2:
            return costCategory.count
        case 3:
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
        case 1:
            return "選擇圖案"
        case 2:
            return "選擇細項"
        case 3:
            if segmentTag == 2 {
                return nil
            } else {
                return "使用QRCode掃描發票"
            }
        default:
            return "備註"
        }
    }

    // swiftlint:disable cyclomatic_complexity
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if segmentTag == 2 {
            if indexPath.section == 0 {
                guard let dateCell = tableView.dequeueReusableCell(
                    withIdentifier: "dateCell") as? AddDateTableViewCell
                else {
                    fatalError("can not create cell")
                }
//                dateCell.backgroundColor = UIColor(red: 245/255, green: 240/255, blue: 206/255, alpha: 1)
                data.dateTime = BBCDateFormatter.shareFormatter.string(from: dateCell.addDatePicker.date)

                dateCell.addDatePicker.date = BBCDateFormatter.shareFormatter.date(from: data.dateTime) ?? Date()

                return dateCell
            } else if indexPath.section == 1 {
                guard let imageCell = tableView.dequeueReusableCell(
                    withIdentifier: ImageTableViewCell.identifier) as? ImageTableViewCell
                else {
                    fatalError("can not create imageCell")
                }
//                imageCell.backgroundColor = UIColor(red: 245/255, green: 240/255, blue: 206/255, alpha: 1)
                imageCell.configure(with: models)

                return imageCell
            } else if indexPath.section == 2 {
                guard let addDataCell = tableView.dequeueReusableCell(
                    withIdentifier: "addDataCell") as? AddNewDataTableViewCell
                else {
                    fatalError("can not create cell")
                }
//                addDataCell.backgroundColor = UIColor(red: 245/255, green: 240/255, blue: 206/255, alpha: 1)
// MARK: - notice
                // 判斷目前在哪一個indexPath.row來決定要給cell的content哪一個array
                switch indexPath.row {
                case 0:
                    addDataCell.contentTextField.text = ""
                case 1:
                    addDataCell.contentTextField.text = ""
                    switch segmentTag {
                    case 0:
                        addDataCell.content = costContent
                        addDataCell.imageArr = costImageArr
                    case 1:
                        addDataCell.content = incomeContent
                        addDataCell.imageArr = incomeImageArr
                    default:
                        addDataCell.content = accountContent
                        addDataCell.imageArr = accountImageArr
                    }
                default:
                    addDataCell.contentTextField.text = ""
                    addDataCell.content = accountContent
                    addDataCell.imageArr = accountImageArr
                }

                // 每次切換segment時，讓顯示金額、種類、帳戶的textField重置（意指把picker先清除），因為在生成cell時會在傳indexPath過去cell時給予對應的picker
                addDataCell.contentTextField.inputView = nil
                // 切換segment時，清除已選圖案
                addDataCell.chooseImage.image = nil
                addDataCell.indexPath = indexPath
                addDataCell.segmentTag = segmentTag
                addDataCell.delegate = self
                // 依照category array裡的資料筆數決定section:1有幾個cell
                addDataCell.fillInContent(name: transferCategory[indexPath.row])
                addDataCell.contentTextField.textAlignment = .center
                addDataCell.contentConfig(segment: segmentTag)
                return addDataCell
            } else if indexPath.section == 3 {
                guard let qrCell = tableView.dequeueReusableCell(
                    withIdentifier: "QRCell") as? QRCodeTableViewCell
                else {
                    fatalError("can not create cell")
                }
//                qrCell.backgroundColor = UIColor(red: 245/255, green: 240/255, blue: 206/255, alpha: 1)
                // 轉帳不需顯示QRCode scanner
                qrCell.qrButton.isHidden = true
                return qrCell
            } else {
                guard let detailCell = tableView.dequeueReusableCell(
                    withIdentifier: "detailCell") as? DetailTableViewCell
                else {
                    fatalError("can not create cell")
                }
//                detailCell.backgroundColor = UIColor(red: 245/255, green: 240/255, blue: 206/255, alpha: 1)
                // 轉帳頁面不需掃描發票，故給空值
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
//                dateCell.backgroundColor = UIColor(red: 245/255, green: 240/255, blue: 206/255, alpha: 1)
                dateCell.delegate = self
                if let dateFromVC = UserDefaults.standard.object(forKey: "currentDate") as? Date {
                    let current = BBCDateFormatter.shareFormatter.string(from: dateFromVC)
                    data.dateTime = current
                    // 讓addNewData的date cell datePicker顯示當前所選取細項的date
                    dateCell.addDatePicker.date = BBCDateFormatter.shareFormatter.date(from: data.dateTime) ?? Date()
                }

                // 執行點選cell的datePicker時給值，回傳給homeVC的data.dateTime & data.monthTime
                dateCell.config()
                // 取dateTime前面到月份formatter的string(pir chart會使用到) - 從homeVC點選月曆時吃的資料
                let monthData = data.dateTime.prefix(11)
                data.monthTime = String(monthData)
                return dateCell
            } else if indexPath.section == 1 {
                guard let imageCell = tableView.dequeueReusableCell(
                    withIdentifier: ImageTableViewCell.identifier) as? ImageTableViewCell
                else {
                    fatalError("can not create imageCell")
                }
//                imageCell.backgroundColor = UIColor(red: 245/255, green: 240/255, blue: 206/255, alpha: 1)
                imageCell.configure(with: models)

                return imageCell
            } else if indexPath.section == 2 {
                guard let addDataCell = tableView.dequeueReusableCell(
                    withIdentifier: "addDataCell") as? AddNewDataTableViewCell
                else {
                    fatalError("can not create cell")
                }
//                addDataCell.backgroundColor = UIColor(red: 245/255, green: 240/255, blue: 206/255, alpha: 1)

// MARK: - notice
                // 判斷目前在哪一個indexPath.row來決定要給cell的content哪一個array
                switch indexPath.row {
                case 0:
                    addDataCell.contentTextField.text = ""
                    addDataCell.contentTextField.text = data.amountTextField
                    // 判斷-當QRCode還沒進行掃描時messageFromQRVC會為空string""，用nil的話會一直成立
                    if messageFromQRVC != "" {
                        var amo = 0
                        for num in 0..<(invoice?.details.count ?? 0) {
                            amo = (amo + (Int(invoice?.details[num].amount ?? "") ?? 0))
                        }
                        addDataCell.contentTextField.text = String(amo)
                    }
                case 1:
                    addDataCell.contentTextField.text = ""
                    addDataCell.contentTextField.text = data.categoryTextField
                    // 切換segment時，清除已選圖案
                    addDataCell.chooseImage.image = nil
                    addDataCell.chooseImage.image = data.categoryImageName.toImage()
                    switch segmentTag {
                    case 0:
                        addDataCell.content = costContent
                        addDataCell.imageArr = costImageArr
                    case 1:
                        addDataCell.content = incomeContent
                        addDataCell.imageArr = incomeImageArr
                    default:
                        addDataCell.content = accountContent
                    }
                default:
                    addDataCell.contentTextField.text = ""
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
            } else if indexPath.section == 3 {
                guard let qrCell = tableView.dequeueReusableCell(
                    withIdentifier: "QRCell") as? QRCodeTableViewCell
                else {
                    fatalError("can not create cell")
                }
//                qrCell.backgroundColor = UIColor(red: 245/255, green: 240/255, blue: 206/255, alpha: 1)
                // 支出、收入要顯示QRCode scanner
                qrCell.qrButton.isHidden = false
                return qrCell
            } else {
                guard let detailCell = tableView.dequeueReusableCell(
                    withIdentifier: "detailCell") as? DetailTableViewCell
                else {
                    fatalError("can not create cell")
                }
//                detailCell.backgroundColor = UIColor(red: 245/255, green: 240/255, blue: 206/255, alpha: 1)
                // 切換不同頁面時，detail要先清空
                detailCell.detailTextView.text = ""
                // 存放invoice的string在fetch data之前要先清空
                items = ""
                // 把message的值塞給detailTextView
                for item in 0..<(invoice?.details.count ?? 0) {
                    guard let invoice = invoice else {
                        fatalError("pass invDetail data error")
                    }
                    items.append("\(invoice.details[item].detailDescription)\n")
                    detailCell.detailTextView.text = items
                    print("=== detailCell.detailTextView.text", detailCell.detailTextView.text)
                }

                detailCell.delegate = self
                return detailCell
            }
        }
    }
}

// date cell - 從addDateCell點選月曆時吃的資料
extension AddNewDataViewController: AddDateTableViewCellDelegate {
    // 用delegate把cell和點選的sender傳過來，進行給新值的動作
    func getDate(_ cell: AddDateTableViewCell, sender: UIDatePicker) {
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
        // date改用string型別存取，因為只需要存"年/月/日"，存時間"時/分"的話後續無法抓取資料
        data.dateTime = BBCDateFormatter.shareFormatter.string(from: sender.date)
    }

    // 用delegate把cell和點選的sender傳過來，進行給month值
    func getMonth(_ cell: AddDateTableViewCell, sender: UIDatePicker) {
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月"
        data.monthTime = BBCDateFormatter.shareFormatter.string(from: sender.date)
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
        case 1:
            data.categoryTextField = textField
        default:
            data.accountTextField = textField
        }
    }

    func getTitle(indexPath: IndexPath, title: String) {
        self.tapIndexpath = indexPath
        data.titleLabel = title
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

    func getImageName(indexPath: IndexPath, imageName: String) {
        self.imageIndexPath = indexPath
        switch imageIndexPath?.row {
        case 1:
            data.categoryImageName = imageName
        default:
            return
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

// date from homeVC
extension AddNewDataViewController: ViewControllerDelegate {
    func getDate(currentDate: String) {
        dateFromHomeVC = currentDate
    }
}

// QRCode text from QRCodeVC
extension AddNewDataViewController: QRCodeViewControllerDelegate {
    func getMessage(message: String) {
        messageFromQRVC = message
    }

    func getInvDetail(didGet items: Invoice) {
        invoice = items
    }

    func getInvDetail(didFailwith error: Error) {
        print("can not parse invoice data")
    }
}
