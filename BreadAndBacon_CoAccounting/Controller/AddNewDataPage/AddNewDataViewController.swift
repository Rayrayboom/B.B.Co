//
//  AddNewDataViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/30.
//

import UIKit
import AVFoundation
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
    // calculator manager
    var logic = BBCoLogicManager()
    var costCategory: [String] = ["金額", "種類", "帳戶"]
    var transferCategory: [String] = ["金額", "來源帳戶", "目的帳戶"]
    // 存支出textField picker資料
    var costContent: [String] = [] {
        didSet {
            addNewDataTableView.reloadData()
        }
    }
    // 存收入textField picker資料
    var incomeContent: [String] = [] {
        didSet {
            addNewDataTableView.reloadData()
        }
    }
    // 存轉帳textField picker資料
    var accountContent: [String] = [] {
        didSet {
            addNewDataTableView.reloadData()
        }
    }
    // 存cost image的資料
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
    var data = NewDataModel()
    var models = [Model]()
    var dateFromHomeVC: String? = ""
    // 存QRCode掃描內容
    var messageFromQRVC: String = ""
    // 存decode後的發票資料
    var invoice: Invoice? {
        didSet {
            DispatchQueue.main.async {
                self.addNewDataTableView.reloadData()
            }
        }
    }
    var items: String = ""

    // for QRCode func use
    var content: String = "" {
        didSet {
            addNewDataTableView.reloadData()
        }
    }
    // 儲存user id到keyChain
    var getId: String = ""
    // alertController
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
//        models.append(Model(text: "早餐", imageName: "Breakfast"))
//        models.append(Model(text: "午餐", imageName: "Lunch"))
//        models.append(Model(text: "午餐", imageName: "Lunch 2"))
//        models.append(Model(text: "晚餐", imageName: "Dinner"))
//        models.append(Model(text: "交通", imageName: "Transportation"))
//        models.append(Model(text: "娛樂", imageName: "Entertainment"))
//        models.append(Model(text: "早餐", imageName: "Breakfast"))
//        models.append(Model(text: "午餐", imageName: "Lunch"))
//        models.append(Model(text: "午餐", imageName: "Lunch 2"))
//        models.append(Model(text: "晚餐", imageName: "Dinner"))
//        models.append(Model(text: "交通", imageName: "Transportation"))
//        models.append(Model(text: "娛樂", imageName: "Entertainment"))

        // 註冊image tableView cell
        addNewDataTableView.register(ImageTableViewCell.nib(), forCellReuseIdentifier: ImageTableViewCell.identifier)
        addNewDataTableView.delegate = self
        addNewDataTableView.dataSource = self
        addNewDataTableView.estimatedRowHeight = UITableView.automaticDimension

        // segmentControl 偵測改值狀態
        didSelectsegmentedControl()
        setupUI()
        // 點選X時，執行取消新增
        cancelNewData()
        // 點選+時，執行新增資料到firebase
        saveNewData()
        
        enum SubCollection: String{
            case expenditure = "expenditure"
            case revenue = "revenue"
            case account = "account"
        }

        // 抓firebase上的支出/收入/轉帳的種類/帳戶pickerView選項資料
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
        // datePicker的格式
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

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
        addNewDataTableView.backgroundColor = UIColor().hexStringToUIColor(hex: "EBE5D9")
        // tableView top內縮10 points
        addNewDataTableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        view.backgroundColor = UIColor().hexStringToUIColor(hex: "1b4464")


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
            sourceSegmentControl.selectedSegmentTintColor = UIColor().hexStringToUIColor(hex: "92c7bd")
        case 2:
            sourceSegmentControl.selectedSegmentTintColor = .systemBrown
        default:
            sourceSegmentControl.selectedSegmentTintColor = UIColor().hexStringToUIColor(hex: "E5BB4B")
        }
        // 切換segment control時，要先把textField和image的資料先清空，否則tableView會去抓前一筆資料的值
        data.amountTextField = ""
        data.categoryTextField = ""
        data.accountTextField = ""
        data.categoryImageName = ""
        data.detailTextView = ""
        addNewDataTableView.reloadData()
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
            image: UIImage(named: "ADD_coData_1"), style: .plain, target: self, action: #selector(savePage))
    }

    // 新增並上傳firebase，用segmentTag來辨識要存到哪個document裡面
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

        // success alert animation
        SPAlert.successAlert()

        self.presentingViewController?.dismiss(animated: true, completion: nil)
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

    // 掃描QRCode error handle
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

    // 分析invoice亂碼string
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
    
    // 計算invoice data總金額 & 細項總和
    func calculateAmountAndCategory(detail: Invoice) {
        // 讓掃描完的amount & detail data自動傳進textField，不需觸發到textFieldDidEndEditing
        self.data.detailTextView = ""
        var amount = 0
        for item in 0..<detail.details.count {
            amount += (Int(detail.details[item].amount) ?? 0)
            self.data.detailTextView +=  "\(detail.details[item].detailDescription)\n"
        }
        self.data.amountTextField = String(amount)
        // 拿到decode data後要更新畫面上的textField，屬於UI設定，故要切回main thread做
        DispatchQueue.main.async {
            self.addNewDataTableView.reloadData()
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
        }
//        else if indexPath.section == 1 {
//            return 80
//        }
        else {
            return UITableView.automaticDimension
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4 //5
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

// MARK: - 轉帳segemant
    // swiftlint:disable cyclomatic_complexity
    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if segmentTag == 2 {
            if indexPath.section == 0 {
                guard let dateCell = tableView.dequeueReusableCell(
                    withIdentifier: "dateCell") as? AddDateTableViewCell
                else {
                    fatalError("can not create cell")
                }
                data.dateTime = BBCDateFormatter.shareFormatter.string(from: dateCell.addDatePicker.date)

                dateCell.addDatePicker.date = BBCDateFormatter.shareFormatter.date(from: data.dateTime) ?? Date()

                return dateCell
            }
//            else if indexPath.section == 1 {
//                guard let imageCell = tableView.dequeueReusableCell(
//                    withIdentifier: ImageTableViewCell.identifier) as? ImageTableViewCell
//                else {
//                    fatalError("can not create imageCell")
//                }
////                imageCell.backgroundColor = UIColor(red: 245/255, green: 240/255, blue: 206/255, alpha: 1)
//                imageCell.configure(with: models)
//
//                return imageCell
//            }
            else if indexPath.section == 1 {
                guard let addDataCell = tableView.dequeueReusableCell(
                    withIdentifier: "addDataCell") as? AddNewDataTableViewCell
                else {
                    fatalError("can not create cell")
                }
                addDataCell.delegate = self
                addDataCell.contentConfig(segment: segmentTag, titleName: transferCategory[indexPath.row])
                // 判斷目前在哪一個indexPath.row來決定要給cell的content哪一個array
                switch indexPath.row {
                case 0:
                    data.amountTextField = addDataCell.amountFromCalculator
                    addDataCell.indexPath = indexPath
                default:
                    addDataCell.setContentAndImage(content: accountContent, image: accountImageArr, indexPath: indexPath, segmentTag: segmentTag)
                }
                return addDataCell
            } else if indexPath.section == 2 {
                guard let qrCell = tableView.dequeueReusableCell(
                    withIdentifier: "QRCell") as? QRCodeTableViewCell
                else {
                    fatalError("can not create cell")
                }
                // 轉帳不需顯示QRCode scanner
                qrCell.qrButton.isHidden = true
                return qrCell
            } else {
                guard let detailCell = tableView.dequeueReusableCell(
                    withIdentifier: "detailCell") as? DetailTableViewCell
                else {
                    fatalError("can not create cell")
                }
                detailCell.delegate = self
                return detailCell
            }
// MARK: - 支出、收入segemant
        } else {
            if indexPath.section == 0 {
                guard let dateCell = tableView.dequeueReusableCell(
                    withIdentifier: "dateCell") as? AddDateTableViewCell
                else {
                    fatalError("can not create cell")
                }
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
            }
//            else if indexPath.section == 1 {
//                guard let imageCell = tableView.dequeueReusableCell(
//                    withIdentifier: ImageTableViewCell.identifier) as? ImageTableViewCell
//                else {
//                    fatalError("can not create imageCell")
//                }
////                imageCell.backgroundColor = UIColor(red: 245/255, green: 240/255, blue: 206/255, alpha: 1)
//                imageCell.configure(with: models)
//
//                return imageCell
//            }
            else if indexPath.section == 1 {
                guard let addDataCell = tableView.dequeueReusableCell(
                    withIdentifier: "addDataCell") as? AddNewDataTableViewCell
                else {
                    fatalError("can not create cell")
                }
                addDataCell.delegate = self
                addDataCell.contentConfig(segment: segmentTag, titleName: costCategory[indexPath.row])
                // 判斷目前在哪一個indexPath.row來決定要給cell的content哪一個array
                switch indexPath.row {
                case 0:
                    addDataCell.contentTextField.text = data.amountTextField
                    addDataCell.indexPath = indexPath
                    // 判斷-當QRCode還沒進行掃描時messageFromQRVC會為空string""，用nil的話會一直成立
                    if messageFromQRVC != "" {
                        // 發票amount資料要塞進data.amountTextField才會真的吃到資料
                        addDataCell.contentTextField.text = data.amountTextField
                    }
                case 1:
                    addDataCell.contentTextField.text = data.categoryTextField
                    addDataCell.chooseImage.image = data.categoryImageName.toImage()
                    switch segmentTag {
                    case 0:
                        addDataCell.setContentAndImage(content: costContent, image: costImageArr, indexPath: indexPath, segmentTag: segmentTag)
                    default:
                        addDataCell.setContentAndImage(content: incomeContent, image: incomeImageArr, indexPath: indexPath, segmentTag: segmentTag)
                    }
                default:
                    addDataCell.setContentAndImage(content: accountContent, image: accountImageArr, indexPath: indexPath, segmentTag: segmentTag)
                }
                return addDataCell
            } else if indexPath.section == 2 {
                guard let qrCell = tableView.dequeueReusableCell(
                    withIdentifier: "QRCell") as? QRCodeTableViewCell
                else {
                    fatalError("can not create cell")
                }
                // 支出、收入要顯示QRCode scanner
                qrCell.qrButton.isHidden = false
                return qrCell
            } else {
                guard let detailCell = tableView.dequeueReusableCell(
                    withIdentifier: "detailCell") as? DetailTableViewCell
                else {
                    fatalError("can not create cell")
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
    // 用delegate把alertVC要用到的present在這邊做，因為cell無法直接用present這個動作，amount textField時顯示計算機，其餘顯示alert
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

    // 新增的選項用delegate傳回來並改變array data，用cell對應回來的indexPath.item才不會在進array時導錯
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
