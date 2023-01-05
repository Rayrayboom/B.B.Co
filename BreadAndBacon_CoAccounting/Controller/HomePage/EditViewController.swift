//
//  EditViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/3.
//  swiftlint:disable line_length

import UIKit
import AVFoundation
import SwiftKeychainWrapper

struct DataModel {
    var amountTextField: String = ""
    var categoryTextField: String = ""
    var accountTextField: String = ""
    var dateTime: String = ""
    var monthTime: String = ""
    var titleLabel: String = ""
    var detailTextView: String = ""
    var categoryImageName: String = ""
    var segmentTag: Int = 0
}

class EditViewController: UIViewController {
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
    var costContent: [String] = [] {
        didSet {
            editTableView.reloadData()
        }
    }
    var incomeContent: [String] = [] {
        didSet {
            editTableView.reloadData()
        }
    }
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
    var incomeImageArr = [UIImage(named: "Bonus"),
                          UIImage(named: "Investments"),
                          UIImage(named: "Salary")]
    var accountImageArr = [UIImage(named: "Add-clicked"),
                           UIImage(named: "Add-unclicked")]
    var segmentTag = 0
    var tapIndexpath: IndexPath?
    var imageIndexPath: IndexPath?
    var editData = DataModel()
    weak var homeVC: ViewController?
    // store decode invoice data
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

    override func viewDidLoad() {
        super.viewDidLoad()
        getId = KeychainWrapper.standard.string(forKey: "id") ?? ""
        editTableView.delegate = self
        editTableView.dataSource = self

        didSelectsegmentedControl()
        setupUI()
        cancelNewData()
        saveEditData()
        
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
        editTableView.backgroundColor = UIColor().hexStringToUIColor(hex: "EBE5D9")
        editTableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
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

    func cancelNewData() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Cancel"), style: .plain, target: self, action: #selector(dismissPage))
    }

    @objc func dismissPage() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func saveEditData() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Pencil_original"), style: .plain, target: self, action: #selector(saveEdit))
    }

    @objc func saveEdit() {
        if editData.amountTextField == "" {
            noAmountAlert()
            return
        }
        self.editAllUser()
    }

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

    func noAmountAlert() {
        controller = UIAlertController(title: "金額不得為空", message: "請輸入金額", preferredStyle: .alert)
        let okAction = UIAlertAction(
            title: "我知道了",
            style: .default, handler: nil)
        controller.addAction(okAction)
        self.present(controller, animated: true, completion: nil)
    }

    func editAllUser() {
        if editData.segmentTag != segmentTag {
            BBCoFireBaseManager.shared.deleteSpecificData(id: getId, subCollection: dataSegmentCategory(), dataId: data?.id ?? "")
            BBCoFireBaseManager.shared.editUserData(tableView: editTableView, id: getId, subCollection: segmentCategory(), date: editData.dateTime, amount: editData.amountTextField, category: editData.categoryTextField, account: editData.accountTextField, month: editData.monthTime, detail: editData.detailTextView, categoryImage: editData.categoryImageName, segment: segmentTag)
        } else {
            BBCoFireBaseManager.shared.editUserDetail(tableView: editTableView, id: getId, subCollection: dataSegmentCategory(), documentID: data?.id ?? "", date: editData.dateTime, amount: editData.amountTextField, category: editData.categoryTextField, account: editData.accountTextField, detail: editData.detailTextView, categoryImage: editData.categoryImageName)
        }
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

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
            print("=== result is \(jsonData)")
            return result
        }catch {
            print("result error")
            return nil
        }
    }

    func calculateAmountAndCategory(detail: Invoice) {
        self.editData.detailTextView = ""
        var amount = 0
        for item in 0..<detail.details.count {
            amount += (Int(detail.details[item].amount) ?? 0)
            self.editData.detailTextView +=  "\(detail.details[item].detailDescription)\n"
        }
        self.editData.amountTextField = String(amount)
        DispatchQueue.main.async {
            self.editTableView.reloadData()
        }
    }
}

extension EditViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        view.endEditing(true)
    }
}

extension EditViewController: UITableViewDataSource {
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
                guard let editTimeCell = tableView.dequeueReusableCell(
                    withIdentifier: "editTimeCell") as? EditTimeTableViewCell
                else {
                    fatalError("can not create cell")
                }
                editTimeCell.delegate = self
                editTimeCell.config(dateTime: editData.dateTime)
                return editTimeCell
            case .category:
                guard let editDataCell = tableView.dequeueReusableCell(withIdentifier: "editDataCell") as? EditDataTableViewCell else {
                    fatalError("can not create cell")
                }
                editDataCell.delegate = self
                editDataCell.contentConfig(segment: segmentTag, indexPath: indexPath, titleName: transferCategory[indexPath.row])
                switch indexPath.row {
                case 0:
                    editDataCell.setContentAndImage(contentPickerView: nil, imagePickerView: nil, content: editData.amountTextField, image: nil, segmentTag: segmentTag)
                case 1:
                    editDataCell.setContentAndImage(contentPickerView: accountContent, imagePickerView: accountImageArr, content: editData.categoryTextField, image: editData.categoryImageName.toImage(), segmentTag: segmentTag)
                default:
                    editDataCell.setContentAndImage(contentPickerView: accountContent, imagePickerView: nil, content: editData.accountTextField, image: nil, segmentTag: segmentTag)
                }
                return editDataCell
            case .qrcode:
                guard let editQRCell = tableView.dequeueReusableCell(
                    withIdentifier: "editQRCell") as? EditQRCodeTableViewCell
                else {
                    fatalError("can not create cell")
                }
                return editQRCell
            case .detail:
                guard let editDetailCell = tableView.dequeueReusableCell(
                    withIdentifier: "editDetailCell") as? EditDetailTableViewCell
                else {
                    fatalError("can not create cell")
                }
                editDetailCell.delegate = self
                editDetailCell.config(detailText: editData.detailTextView)
                return editDetailCell
            }
        default:
            switch section {
            case .date:
                guard let editTimeCell = tableView.dequeueReusableCell(
                    withIdentifier: "editTimeCell") as? EditTimeTableViewCell
                else {
                    fatalError("can not create cell")
                }
                editTimeCell.delegate = self
                editTimeCell.config(dateTime: editData.dateTime)
                return editTimeCell
            case .category:
                guard let editDataCell = tableView.dequeueReusableCell(withIdentifier: "editDataCell") as? EditDataTableViewCell else {
                    fatalError("can not create cell")
                }
                editDataCell.delegate = self
                editDataCell.contentConfig(segment: segmentTag, indexPath: indexPath, titleName: costCategory[indexPath.row])
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
            case .qrcode:
                guard let editQRCell = tableView.dequeueReusableCell(
                    withIdentifier: "editQRCell") as? EditQRCodeTableViewCell
                else {
                    fatalError("can not create cell")
                }
                return editQRCell
            case .detail:
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

extension EditViewController: EditTimeTableViewCellDelegate {
    func getDate(_ cell: EditTimeTableViewCell, sender: UIDatePicker) {
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
        editData.dateTime = BBCDateFormatter.shareFormatter.string(from: sender.date)
    }
}

// new data cell
extension EditViewController: EditDataTableViewCellDelegate {
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
        // decode invoice
        self.decodeInvoice(message: message)
    }
}
