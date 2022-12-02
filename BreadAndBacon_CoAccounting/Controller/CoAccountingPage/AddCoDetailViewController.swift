//
//  AddCoDetailViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/10.
//

import UIKit
import FirebaseFirestore
import CoreAudio
import SPAlert

// MARK: - expenditure
struct CoDataModel {
    var itemTextField: String = ""
    var amountTextField: String = ""
    var userTextField: String = ""
    // date改用string型別存取，因為只需要存"年/月/日"，存時間"時/分"的話後續無法抓取資料
    var dateTime: String = ""
    var monthTime: String = ""
}

class AddCoDetailViewController: UIViewController {
    // 判斷是否是要來編輯，true是來編輯資料，false則是新增資料
    var isEdit: Bool = false
    let sectionTitle = ["日期", "品項", "金額", "付款人"]
    var tapIndexpath: IndexPath?
    var data = CoDataModel()
    // 用來儲存目前已新增的資料array(資料從CoAccountVC傳來)
    var currentData: Account?

    // 用來存所點選之帳本的id(用來新增對應帳本detail)
    var didSelecetedBook: String = ""

    // 存付款者textField picker資料，後續由加好友時抓取firebase資料，用didSet
    var userContent: [String] = [] {
        didSet {
            coDetailTableView.reloadData()
        }
    }
    // alertController
    var controller = UIAlertController()

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var coDetailTableView: UITableView!
    @IBAction func dismissDetail(_ sender: UIButton) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @IBOutlet weak var saveCoDetailBO: UIButton!
    // 存detail到firebase並dismiss addCoDetailVC
    @IBAction func saveCoDetail(_ sender: Any) {
        if data.amountTextField == "" {
            noAmountAlert()
            return
        }
        if isEdit == false {
            createCoAccountData(document: didSelecetedBook, subCollection: "co_expenditure")
        } else {
            editUser(document: didSelecetedBook, subCollection: "co_expenditure", documentID: currentData?.id ?? "")
        }
        // success alert animation
        SPAlert.successAlert()
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        coDetailTableView.delegate = self
        coDetailTableView.dataSource = self
        // 抓取現有user data
        fetchUser(didSelecetedBook: didSelecetedBook)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presentationController?.presentingViewController.viewWillAppear(true)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    // UI
    func setupUI() {
        saveCoDetailBO.layer.cornerRadius = 10
        self.titleLabel.text = isEdit ? "編輯 支出" : "新 支出"
        if isEdit == false {
            self.saveCoDetailBO.setTitle("Save", for: .normal)
        } else {
            self.saveCoDetailBO.setTitle("Edit", for: .normal)
        }

        coDetailTableView.backgroundColor = UIColor().hexStringToUIColor(hex: "EBE5D9")
        // tableView top內縮10 points
        coDetailTableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        saveCoDetailBO.backgroundColor = UIColor().hexStringToUIColor(hex: "E5BB4B")
        saveCoDetailBO.layer.borderWidth = 4
        saveCoDetailBO.layer.borderColor = CGColor(red: 145/255, green: 145/255, blue: 145/255, alpha: 1)
        view.backgroundColor = UIColor().hexStringToUIColor(hex: "1b4464")
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

    // MARK: - 上傳資料到Firebase
    func createCoAccountData(document: String, subCollection: String) {
        guard let cell = coDetailTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? CoTimeTableViewCell
        else {
            fatalError("can not find CoTimeTableViewCell")
        }
        let dataBase = Firestore.firestore()
        let documentID = dataBase.collection("co-account")
            .document(document)
            .collection(subCollection)
            .document()
        // 讓swift code先去生成一組id並存起來，後續要識別document修改資料用
        let identifier = documentID.documentID
        // 需存id，後續delete要抓取ID刪除對應資料
        let account = Account(
            id: identifier,
            amount: data.amountTextField,
            category: data.itemTextField,
            account: nil,
            date: BBCDateFormatter.shareFormatter.string(from: cell.datePicker.date), //data.dateTime,
            month: data.monthTime,
            destinationAccountId: nil,
            sourceAccountId: nil,
            accountId: nil,
            expenditureId: "expenditureId",
            revenueId: nil,
            detail: nil,
            user: data.userTextField,
            categoryImage: nil,
            segmentTag: nil)
        do {
            try documentID.setData(from: account)
            print("success create document. ID: \(documentID.documentID)")
        } catch {
            print(error)
        }
    }

    // 從Firebase上fetch全部user資料，並append到userContent裡
    func fetchUser(didSelecetedBook: String) {
        userContent = []
        let dataBase = Firestore.firestore()
        let docRef = dataBase.collection("co-account").document(didSelecetedBook)

        docRef.getDocument { (document, error) in
            if let document = document, document.exists,
               let data = try? document.data(as: Book.self)
            {
                self.userContent.append(contentsOf: data.userId)
            } else {
                print("Document does not exist")
            }
        }
    }

    // 點選對應細項編輯資料
    func editUser(document: String, subCollection: String, documentID: String) {
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
        // 把indexPath(0, 0)的位置指向CoTimeTableViewCell，去cell裡面拿東西（非生成cell實例）
        guard let cell = coDetailTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? CoTimeTableViewCell else {
            fatalError("can not find CoTimeTableViewCell")
        }
        let dataBase = Firestore.firestore()
        dataBase.collection("co-account/\(document)/\(subCollection)").document("\(documentID)").updateData([
            // 這邊兩種方法都可以，因為data.dateTime也透過cell的delegate塞了cell的date資料了，(針對date讓一開始顯示畫面時就先吃到datePicker的資料，不用等到點選變更後才塞資料)
            "date": data.dateTime,
            //BBCDateFormatter.shareFormatter.string(from: cell.datePicker.date),
            "amount": data.amountTextField,
            "category": data.itemTextField,
            "user": data.userTextField
        ]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document update successfully ")
            }
        }
    }
}

extension AddCoDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 點選cell時觸發點選效果
        tableView.deselectRow(at: indexPath, animated: true)
        // 把當前點到的indexPath傳到cell的indexPath
        tapIndexpath = indexPath
        // 點擊cell時收起鍵盤
        view.endEditing(true)
        print(indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension AddCoDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitle.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return sectionTitle[section]
        case 1:
            return sectionTitle[section]
        case 2:
            return sectionTitle[section]
        default:
            return sectionTitle[section]
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let coDetailCell = tableView.dequeueReusableCell(withIdentifier: "coDetailCell") as? CoDetailTableViewCell
        else {
            fatalError("can not create coDetailCell")
        }
        coDetailCell.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        coDetailCell.indexPath = indexPath
        coDetailCell.delegate = self
        coDetailCell.contentTextField.textAlignment = .center

        switch indexPath.section {
        case 0: // 針對time設定
            guard let coTimeCell = tableView.dequeueReusableCell(withIdentifier: "coTimeCell") as? CoTimeTableViewCell
            else {
                fatalError("can not create coTimeCell")
            }
            coTimeCell.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")

            coTimeCell.delegate = self
            // 執行點選cell的datePicker時給值，回傳給coAccountVC的data.dateTime
            coTimeCell.config()
            // 編輯狀態時偵測被點選品項並塞值給datePicker，若非編輯狀態(新增)則帶入當天日期
            data.dateTime = isEdit ? (currentData?.date)! : data.dateTime
// MARK: - have "!" issue & will crash (新增完品項後不能直接點編輯)
//            guard let dateTimeInDate = BBCDateFormatter.shareFormatter.date(from: data.dateTime) else {
//                fatalError("can not transfer date")
//            }
// MARK: - crash here "BBCDateFormatter.shareFormatter.date(from: data.dateTime) ?? Date() : Date()"
            // 讓edit/addNew的time cell datePicker顯示當前所選取細項的date
            coTimeCell.datePicker.date = isEdit ?  BBCDateFormatter.shareFormatter.date(from: data.dateTime) ?? Date() : Date()
            return coTimeCell

        case 3: // 針對付款者textField設定，編輯狀態時偵測被點選品項並塞值給textField
            // 計算userContent裡面有幾個user的資料，因為是一筆一筆的array，所以用userContent.count，透過for迴圈把array裡的user name append進去content array裡(要塞進pickerView的資料)
            for user in userContent {
                coDetailCell.content.append(user)
            }
// MARK: - have "!" issue
//            guard let user = currentData[tapIndexpath?.row ?? 0].user else { fatalError() }
            data.userTextField = isEdit ? (currentData?.user)! : ""
            coDetailCell.contentTextField.text = isEdit ? data.userTextField : ""
            return coDetailCell
        case 2: // 針對金額textField設定，編輯狀態時偵測被點選品項並塞值給textField
            data.amountTextField = isEdit ? (currentData?.amount)! : ""
            coDetailCell.contentTextField.text = isEdit ? data.amountTextField : ""
            return coDetailCell
        default: // 針對品項textField設定，編輯狀態時偵測被點選品項並塞值給textField
// MARK: - have "!" issue
//            guard let category = currentData[tapIndexpath?.row ?? 0].category else { fatalError() }
            data.itemTextField = isEdit ? (currentData?.category)! : ""
            coDetailCell.contentTextField.text = isEdit ? data.itemTextField : ""
            return coDetailCell
        }
    }
}

extension AddCoDetailViewController: CoTimeTableViewCellDelegate {
    func getDate(_: CoTimeTableViewCell, sender: UIDatePicker) {
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
        data.dateTime = BBCDateFormatter.shareFormatter.string(from: sender.date)
        print("=== is delegate datetime", data.dateTime)
    }
}

// new coDetail cell
extension AddCoDetailViewController: CoDetailTableViewCellDelegate {
    func getInputTextField(indexPath: IndexPath, textField: String) {
        self.tapIndexpath = indexPath
        switch tapIndexpath?.section {
        case 1:
            data.itemTextField = textField
            print("======= this is itemTextField \(data.itemTextField)")
        case 2:
            data.amountTextField = textField
            print("======= this is amountTextField \(data.amountTextField)")
        default:
            data.userTextField = textField
            print("======= this is userTextField \(data.userTextField)")
        }
    }
}
