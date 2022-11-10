//
//  AddCoDetailViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/10.
//

import UIKit
import FirebaseFirestore


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
    let sectionTitle = ["日期", "品項", "金額", "付款人"]
    var tapIndexpath: IndexPath?
    var data = CoDataModel()
    // 存付款者textField picker資料，後續由加好友時抓取firebase資料，用didSet
    var userContent: [String] = ["Ray", "Jennifer"]
//    {
//        didSet {
//            print("=== this is all userContent \(self.userContent)")
//            coDetailTableView.reloadData()
//        }
//    }

    @IBOutlet weak var coDetailTableView: UITableView!
    @IBAction func dismissDetail(_ sender: UIButton) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @IBAction func saveCoDetail(_ sender: Any) {
        createCoAccountData(subCollection: "co_expenditure")
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        coDetailTableView.delegate = self
        coDetailTableView.dataSource = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("disappear")
        presentationController?.presentingViewController.viewWillAppear(true)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    // MARK: - 上傳資料到Firebase
    func createCoAccountData(subCollection: String) {
        let dataBase = Firestore.firestore()
        let fetchDocumentID = dataBase.collection("co-account")
            .document("U5nzbfkDyHNIXAvVUdZD")
            .collection(subCollection)
            .document()
        // 讓swift code先去生成一組id並存起來，後續要識別document修改資料用
        let identifier = fetchDocumentID.documentID
        // 需存id，後續delete要抓取ID刪除對應資料
        let account = Account(
            id: identifier,
            amount: data.amountTextField,
            category: data.itemTextField,
            account: nil,
            date: data.dateTime,
            month: data.monthTime,
            destinationAccountId: nil,
            sourceAccountId: nil,
            accountId: nil,
            expenditureId: "expenditureId",
            revenueId: nil,
            detail: nil,
            user: data.userTextField)
        do {
            try fetchDocumentID.setData(from: account)
            print("success create document. ID: \(fetchDocumentID.documentID)")
        } catch {
            print(error)
        }
    }
}

extension AddCoDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
        // 把當前點到的indexPath傳到cell的indexPath
        tapIndexpath = indexPath
        // 點擊cell時收起鍵盤
        view.endEditing(true)
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
        switch indexPath.section {
        case 0:
            guard let coTimeCell = tableView.dequeueReusableCell(withIdentifier: "coTimeCell") as? CoTimeTableViewCell else {
                fatalError("can not create coTimeCell")
            }
            
            coTimeCell.delegate = self
            coTimeCell.config()
            return coTimeCell
        default:
            guard let coDetailCell = tableView.dequeueReusableCell(withIdentifier: "coDetailCell") as? CoDetailTableViewCell else {
                fatalError("can not create coDetailCell")
            }

            coDetailCell.delegate = self
            coDetailCell.indexPath = indexPath
            coDetailCell.contentTextField.textAlignment = .center

            switch indexPath.section {
            case 3:
                coDetailCell.content = userContent
            default:
                break
            }

            return coDetailCell
        }
    }
}

// date cell
extension AddCoDetailViewController: CoTimeTableViewCellDelegate {
    // 用delegate把cell和點選的sender傳過來，進行給新值的動作
    func getDate(_ cell: CoTimeTableViewCell, sender: UIDatePicker) {
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
        // date改用string型別存取，因為只需要存"年/月/日"，存時間"時/分"的話後續無法抓取資料
        data.dateTime = BBCDateFormatter.shareFormatter.string(from: sender.date)
        print("this is dateTime \(data.dateTime)")
    }

    // 用delegate把cell和點選的sender傳過來，進行給month值
    func getMonth(_ cell: CoTimeTableViewCell, sender: UIDatePicker) {
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月"
        data.monthTime = BBCDateFormatter.shareFormatter.string(from: sender.date)
        print("this is monthTime \(data.monthTime)")
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
