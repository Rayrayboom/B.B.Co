//
//  AddCoDetailViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/10.
//  swiftlint:disable line_length

import UIKit
import SPAlert

struct CoDataModel {
    var itemTextField: String = ""
    var amountTextField: String = ""
    var userTextField: String = ""
    var dateTime: String = ""
    var monthTime: String = ""
}

class AddCoDetailViewController: UIViewController {
    var isEdit: Bool = false
    var tapIndexpath: IndexPath?
    var data = CoDataModel()
    let sectionTitle = ["日期", "品項", "金額", "付款人"]
    var currentData: Account?
    var didSelecetedBook: String = ""
    var userContent: [String] = [] {
        didSet {
            coDetailTableView.reloadData()
        }
    }
    var controller = UIAlertController()
    var closure: ((String) -> (Void))?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var coDetailTableView: UITableView!
    @IBAction func dismissDetail(_ sender: UIButton) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @IBOutlet weak var saveCoDetailBO: UIButton!
    @IBAction func saveCoDetail(_ sender: Any) {
        if data.amountTextField == "" {
            noAmountAlert()
            return
        }
        if isEdit == false {
            BBCoFireBaseManager.shared.createCoAccountData(tableView: coDetailTableView, document: didSelecetedBook, subCollection: SubCategory.coExpenditure, amount: data.amountTextField, category: data.itemTextField, month: data.monthTime, user: data.userTextField)
        } else {
            BBCoFireBaseManager.shared.editUser(tableView: coDetailTableView, document: didSelecetedBook, subCollection: SubCategory.coExpenditure, documentID: currentData?.id ?? "", date: data.dateTime, amount: data.amountTextField, category: data.itemTextField, user: data.userTextField)
        }
        SPAlert.successAlert()
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        coDetailTableView.delegate = self
        coDetailTableView.dataSource = self
        BBCoFireBaseManager.shared.fetchMember(didSelecetedBook: didSelecetedBook) { result in
            self.userContent += result
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presentationController?.presentingViewController.viewWillAppear(true)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

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

    func noAmountAlert() {
        controller = UIAlertController(title: "金額不得為空", message: "請輸入金額", preferredStyle: .alert)
        let okAction = UIAlertAction(
            title: "我知道了",
            style: .default, handler: nil)
        controller.addAction(okAction)
        self.present(controller, animated: true, completion: nil)
    }
}

extension AddCoDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        tapIndexpath = indexPath
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
        guard let coDetailCell = tableView.dequeueReusableCell(withIdentifier: Identifier.coDetailCellID) as? CoDetailTableViewCell
        else {
            fatalError(ErrorMessage.fatalErrorMSG)
        }
        coDetailCell.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        coDetailCell.indexPath = indexPath
        coDetailCell.delegate = self
        coDetailCell.contentTextField.textAlignment = .center

        switch indexPath.section {
        case 0: 
            guard let coTimeCell = tableView.dequeueReusableCell(withIdentifier: Identifier.coTimeCellID) as? CoTimeTableViewCell
            else {
                fatalError(ErrorMessage.fatalErrorMSG)
            }
            coTimeCell.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")

            coTimeCell.delegate = self
            coTimeCell.config()
            data.dateTime = isEdit ? (currentData?.date)! : data.dateTime
            coTimeCell.datePicker.date = isEdit ?  BBCDateFormatter.shareFormatter.date(from: data.dateTime) ?? Date() : Date()
            return coTimeCell

        case 3:
            for user in userContent {
                coDetailCell.content.append(user)
            }
            data.userTextField = isEdit ? (currentData?.user)! : ""
            coDetailCell.contentTextField.text = isEdit ? data.userTextField : ""
            return coDetailCell
        case 2:
            data.amountTextField = isEdit ? (currentData?.amount)! : ""
            coDetailCell.contentTextField.text = isEdit ? data.amountTextField : ""
            return coDetailCell
        default:
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
    }
}

// new coDetail cell
extension AddCoDetailViewController: CoDetailTableViewCellDelegate {
    func getInputTextField(indexPath: IndexPath, textField: String) {
        self.tapIndexpath = indexPath
        switch tapIndexpath?.section {
        case 1:
            data.itemTextField = textField
        case 2:
            data.amountTextField = textField
        default:
            data.userTextField = textField
        }
    }

    func addNewContent(_ cell: CoDetailTableViewCell, indexPathItem: Int) {
        present(cell.presentCalculateVC ?? UIViewController(), animated: true)
    }
}
