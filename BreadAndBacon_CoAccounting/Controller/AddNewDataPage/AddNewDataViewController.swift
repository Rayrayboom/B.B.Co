//
//  AddNewDataViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/30.
//  swiftlint:disable line_length

import UIKit
import AVFoundation
import SwiftKeychainWrapper
import SPAlert

struct NewDataModel {
    var amountTextField: String = ""
    var categoryTextField: String = ""
    var accountTextField: String = ""
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
    enum Segment: CaseIterable {
        case expenditure
        case revenue
        case account
    }
    enum Section: CaseIterable {
        case date
        case category
        case qrcode
        case detail
    }
    enum Row: CaseIterable {
        case amount
        case category
        case fromAccount
    }
    var logic = BBCoLogicManager()
    var costCategory: [String] = ["金額", "種類", "帳戶"]
    var transferCategory: [String] = ["金額", "來源帳戶", "目的帳戶"]
    var costContent: [String] = [] {
        didSet {
            addNewDataTableView.reloadData()
        }
    }
    var incomeContent: [String] = [] {
        didSet {
            addNewDataTableView.reloadData()
        }
    }
    var accountContent: [String] = [] {
        didSet {
            addNewDataTableView.reloadData()
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
    var incomeImageArr = [UIImage(named: "Bonus"),
                          UIImage(named: "Investments"),
                          UIImage(named: "Salary")]
    var accountImageArr = [UIImage(named: "Add-clicked"),
                           UIImage(named: "Add-unclicked")]
    var segmentTag = 0
    var tapIndexpath: IndexPath?
    var imageIndexPath: IndexPath?
    var data = NewDataModel()
    var ID = Identifier()
    var errorMessage = ErrorMessage()
    var models = [Model]()
    var dateFromHomeVC: String? = ""
    var messageFromQRVC: String = ""
    // store decode invoice data
    var invoice: Invoice? {
        didSet {
            DispatchQueue.main.async {
                self.addNewDataTableView.reloadData()
            }
        }
    }
    var items: String = ""
    var content: String = "" {
        didSet {
            addNewDataTableView.reloadData()
        }
    }
    var getId: String = ""
    var controller = UIAlertController()
    let group = DispatchGroup()

    @IBOutlet weak var addNewDataTableView: UITableView!

    @IBOutlet weak var sourceSegmentControl: UISegmentedControl!

    @IBAction func insertQRCode(_ sender: UIButton) {
        guard let presentQRScanVC = self.storyboard?.instantiateViewController(withIdentifier: "qrScanVC") as? QRCodeViewController else {
            fatalError("can not find QRScanner VC")
        }
        presentQRScanVC.delegate = self
        self.present(presentQRScanVC, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        getId = KeychainWrapper.standard.string(forKey: "id") ?? ""
        addNewDataTableView.register(ImageTableViewCell.nib(), forCellReuseIdentifier: ImageTableViewCell.identifier)
        addNewDataTableView.delegate = self
        addNewDataTableView.dataSource = self
        addNewDataTableView.estimatedRowHeight = UITableView.automaticDimension
        didSelectsegmentedControl()
        setupUI()
        cancelNewData()
        saveNewData()
        
        enum SubCollection: String{
            case expenditure = "expenditure"
            case revenue = "revenue"
            case account = "account"
        }

        for subCollection in [SubCollection.expenditure, SubCollection.revenue, SubCollection.account] {
            var contentArray = BBCoFireBaseManager.shared.fetchUserCategory(id: getId, subCollection: subCollection.rawValue) {
                result in
                switch subCollection {
                case .expenditure:
                    self.costContent = result
                    print("=== costContent", self.costContent)
                case .revenue:
                    self.incomeContent = result
                    print("=== incomeContent", self.incomeContent)
                case .account:
                    self.accountContent = result
                    print("=== accountContent", self.accountContent)
                }
            }
        }
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    func setupUI() {
        sourceSegmentControl.layer.borderWidth = 1.5
        sourceSegmentControl.layer.borderColor = CGColor(red: 233/255, green: 229/255, blue: 218/255, alpha: 1)
        if sourceSegmentControl.selectedSegmentIndex == 0 {
            sourceSegmentControl.selectedSegmentTintColor = UIColor().hexStringToUIColor(hex: "E5BB4B")
            let segementTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            sourceSegmentControl.setTitleTextAttributes(segementTextAttributes, for: .normal)
        }
        addNewDataTableView.backgroundColor = UIColor().hexStringToUIColor(hex: "EBE5D9")
        addNewDataTableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        view.backgroundColor = UIColor().hexStringToUIColor(hex: "1b4464")
    }

    func didSelectsegmentedControl() {
        sourceSegmentControl.addTarget(self, action: #selector(handleSegmentControl), for: .valueChanged)
    }

    @objc func handleSegmentControl() {
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        sourceSegmentControl.setTitleTextAttributes(titleTextAttributes, for: .selected)
        segmentTag = sourceSegmentControl.selectedSegmentIndex
        switch segmentTag {
        case 1:
            sourceSegmentControl.selectedSegmentTintColor = UIColor().hexStringToUIColor(hex: "92c7bd")
        case 2:
            sourceSegmentControl.selectedSegmentTintColor = .systemBrown
        default:
            sourceSegmentControl.selectedSegmentTintColor = UIColor().hexStringToUIColor(hex: "E5BB4B")
        }
        data.amountTextField = ""
        data.categoryTextField = ""
        data.accountTextField = ""
        data.categoryImageName = ""
        data.detailTextView = ""
        addNewDataTableView.reloadData()
    }

    func cancelNewData() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Cancel"), style: .plain, target: self, action: #selector(dismissPage))
    }

    @objc func dismissPage() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func saveNewData() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "ADD_coData_1"), style: .plain, target: self, action: #selector(savePage))
    }

    @objc func savePage() {
        if data.amountTextField == "" {
            noAmountAlert()
            return
        }
        switch segmentTag {
        case 0:
            BBCoFireBaseManager.shared.createUserData(id: getId, subCollection: "expenditure", amount: data.amountTextField, category: data.categoryTextField, account: data.accountTextField, date: data.dateTime, month: data.monthTime, detail: data.detailTextView, categoryImage: data.categoryImageName, segment: segmentTag)
        case 1:
            BBCoFireBaseManager.shared.createUserData(id: getId, subCollection: "revenue", amount: data.amountTextField, category: data.categoryTextField, account: data.accountTextField, date: data.dateTime, month: data.monthTime, detail: data.detailTextView, categoryImage: data.categoryImageName, segment: segmentTag)
        default:
            BBCoFireBaseManager.shared.createUserData(id: getId, subCollection: "account", amount: data.amountTextField, category: data.categoryTextField, account: data.accountTextField, date: data.dateTime, month: data.monthTime, detail: data.detailTextView, categoryImage: data.categoryImageName, segment: segmentTag)
        }
        SPAlert.successAlert()
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func noAmountAlert() {
        controller = UIAlertController(title: "金額不得為空", message: "請輸入金額", preferredStyle: .alert)
        let okAction = UIAlertAction(
            title: "我知道了",
            style: .default, handler: nil)
        controller.addAction(okAction)
        self.present(controller, animated: true, completion: nil)
    }

    func parseErrorAlert() {
        self.controller = UIAlertController(title: "Oops, 系統有點問題，請再試一次", message: nil, preferredStyle: .alert)

        let okAction = UIAlertAction(
            title: "再試一次",
            style: .default) { action in
                guard let presentQRScanVC = self.storyboard?.instantiateViewController(withIdentifier: "qrScanVC") as? QRCodeViewController else {
                    fatalError("can not find QRScanner VC")
                }
                presentQRScanVC.delegate = self
                self.present(presentQRScanVC, animated: true)
            }
        self.controller.addAction(okAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        self.controller.addAction(cancelAction)
        // 顯示提示框
        self.present(self.controller, animated: true, completion: nil)
    }

    func decodeInvoice(message: String) {
        let invNum = message.prefix(10)
        let message = message
        let encrypt = message.prefix(24)
        var invYear = (message as NSString).substring(with: NSMakeRange(10, 3))
        let translateYear = (Int(invYear) ?? 0) + 1911
        invYear = String(translateYear)

        let invMonth = (message as NSString).substring(with: NSMakeRange(13, 2))
        let invDay = (message as NSString).substring(with: NSMakeRange(15, 2))
        let randomNumber = (message as NSString).substring(with: NSMakeRange(17, 4))
        let sellerID = (message as NSString).substring(with: NSMakeRange(45, 8))

        // POST API
        sendInvoiceAPI(invNum: String(invNum), invDate: "\(invYear)/\(invMonth)/\(invDay)", encrypt: String(encrypt), sellerID: sellerID, randomNumber: randomNumber)

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

    // after POST API, 解析invoice data
    func parseData(jsonData: Data) -> Invoice? {
        do {
            let result = try JSONDecoder().decode(Invoice.self, from: jsonData)
            print("=== this is result \(result)")
            return result
        } catch {
            print("result error")
            return nil
        }
    }

    func calculateAmountAndCategory(detail: Invoice) {
        self.data.detailTextView = ""
        var amount = 0
        for item in 0..<detail.details.count {
            amount += (Int(detail.details[item].amount) ?? 0)
            self.data.detailTextView +=  "\(detail.details[item].detailDescription)\n"
        }
        self.data.amountTextField = String(amount)
        DispatchQueue.main.async {
            self.addNewDataTableView.reloadData()
        }
    }
}

extension AddNewDataViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tapIndexpath = indexPath
        view.endEditing(true)
    }
}

extension AddNewDataViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = Section.allCases[indexPath.section]
        switch section {
        case .detail:
            return 250
        default:
            return UITableView.automaticDimension
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let segment = Segment.allCases[sourceSegmentControl.selectedSegmentIndex]
        let section = Section.allCases[section]
        switch section {
        case .date:
            return 1
        case .category:
            return costCategory.count
        case .qrcode:
            switch segment {
            case .account:
                return 0
            default:
                return 1
            }
        case .detail:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let segment = Segment.allCases[sourceSegmentControl.selectedSegmentIndex]
        let section = Section.allCases[section]
        switch section {
        case .date:
            return "選擇日期"
        case .category:
            return "選擇細項"
        case .qrcode:
            switch segment {
            case .account:
                return nil
            default:
                return "使用QRCode掃描發票"
            }
        case .detail:
            return "備註"
        }
    }

    // swiftlint:disable cyclomatic_complexity
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let segment = Segment.allCases[sourceSegmentControl.selectedSegmentIndex]
        let section = Section.allCases[indexPath.section]
        let row = Row.allCases[indexPath.row]
        switch segment {
        case .account:
            switch section {
            case .date:
                guard let dateCell = tableView.dequeueReusableCell(
                    withIdentifier: ID.addDataDateCellID) as? AddDateTableViewCell
                else {
                    fatalError(errorMessage.fatalErrorMSG)
                }
                dateCell.delegate = self
                dateCell.config(currentDate: data.dateTime)
                return dateCell
            case .category:
                guard let addDataCell = tableView.dequeueReusableCell(
                    withIdentifier: ID.addDataDataCellID) as? AddNewDataTableViewCell
                else {
                    fatalError(errorMessage.fatalErrorMSG)
                }
                addDataCell.delegate = self
                addDataCell.contentConfig(segment: segmentTag, titleName: transferCategory[indexPath.row])
                // 判斷目前在哪一個indexPath.row來決定要給cell的content哪一個array
                switch row {
                case .amount:
                    data.amountTextField = addDataCell.amountFromCalculator
                    addDataCell.indexPath = indexPath
                default:
                    addDataCell.setContentAndImage(content: accountContent, image: accountImageArr, indexPath: indexPath, segmentTag: segmentTag)
                }
                return addDataCell
            case .qrcode:
                guard let qrCell = tableView.dequeueReusableCell(
                    withIdentifier: ID.addDataQRCellID) as? QRCodeTableViewCell
                else {
                    fatalError(errorMessage.fatalErrorMSG)
                }
                // 轉帳不需顯示QRCode scanner
                qrCell.qrButton.isHidden = true
                return qrCell
            case .detail:
                guard let detailCell = tableView.dequeueReusableCell(
                    withIdentifier: ID.addDataDetailCellID) as? DetailTableViewCell
                else {
                    fatalError(errorMessage.fatalErrorMSG)
                }
                detailCell.delegate = self
                return detailCell
            }
        default:
            switch section {
            case .date:
                guard let dateCell = tableView.dequeueReusableCell(
                    withIdentifier: ID.addDataDateCellID) as? AddDateTableViewCell
                else {
                    fatalError(errorMessage.fatalErrorMSG)
                }
                dateCell.delegate = self
                if let dateFromVC = UserDefaults.standard.object(forKey: "currentDate") as? Date, data.dateTime == "" {
                    BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
                    let current = BBCDateFormatter.shareFormatter.string(from: dateFromVC)
                    data.dateTime = current
                }
                dateCell.config(currentDate: data.dateTime)
                let monthData = data.dateTime.prefix(11)
                data.monthTime = String(monthData)
                return dateCell
            case .category:
                guard let addDataCell = tableView.dequeueReusableCell(
                    withIdentifier: ID.addDataDataCellID) as? AddNewDataTableViewCell
                else {
                    fatalError(errorMessage.fatalErrorMSG)
                }
                addDataCell.delegate = self
                addDataCell.contentConfig(segment: segmentTag, titleName: costCategory[indexPath.row])
                switch row {
                case .amount:
                    addDataCell.contentTextField.text = data.amountTextField
                    addDataCell.indexPath = indexPath
                    if messageFromQRVC != "" {
                        addDataCell.contentTextField.text = data.amountTextField
                    }
                case .category:
                    addDataCell.contentTextField.text = data.categoryTextField
                    addDataCell.chooseImage.image = data.categoryImageName.toImage()
                    switch segmentTag {
                    case 0:
                        addDataCell.setContentAndImage(content: costContent, image: costImageArr, indexPath: indexPath, segmentTag: segmentTag)
                    default:
                        addDataCell.setContentAndImage(content: incomeContent, image: incomeImageArr, indexPath: indexPath, segmentTag: segmentTag)
                    }
                case .fromAccount:
                    addDataCell.setContentAndImage(content: accountContent, image: accountImageArr, indexPath: indexPath, segmentTag: segmentTag)
                }
                return addDataCell
            case .qrcode:
                guard let qrCell = tableView.dequeueReusableCell(
                    withIdentifier: ID.addDataQRCellID) as? QRCodeTableViewCell
                else {
                    fatalError(errorMessage.fatalErrorMSG)
                }
                qrCell.qrButton.isHidden = false
                return qrCell
            case .detail:
                guard let detailCell = tableView.dequeueReusableCell(
                    withIdentifier: ID.addDataDetailCellID) as? DetailTableViewCell
                else {
                    fatalError(errorMessage.fatalErrorMSG)
                }
                detailCell.delegate = self
                detailCell.config(detailText: data.detailTextView)
                return detailCell
            }
        }
    }
}

// date cell - 從addDateCell點選月曆時吃的資料
extension AddNewDataViewController: AddDateTableViewCellDelegate {
    func getDate(_ cell: AddDateTableViewCell, sender: UIDatePicker) {
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
        // date改用string型別存取，因為只需要存"年/月/日"，存時間"時/分"的話後續無法抓取資料
        data.dateTime = BBCDateFormatter.shareFormatter.string(from: sender.date)
    }

    func getMonth(_ cell: AddDateTableViewCell, sender: UIDatePicker) {
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月"
        data.monthTime = BBCDateFormatter.shareFormatter.string(from: sender.date)
    }
}

// new data cell
extension AddNewDataViewController: AddNewDataTableViewCellDelegate {
    func addNewContent(_ cell: AddNewDataTableViewCell, indexPathItem: Int) {
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

    func setContent(indexPathItem: Int, content: [String]) {
        switch segmentTag {
        case 0:
            if indexPathItem == 1 {
                costContent = content
            } else {
                accountContent = content
            }
        case 1:
            if indexPathItem == 1 {
                incomeContent = content
            } else {
                accountContent = content
            }
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
        self.decodeInvoice(message: message)
    }
}
