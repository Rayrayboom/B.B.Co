//
//  AddNewDataTableViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/30.
//

import UIKit

protocol AddNewDataTableViewCellDelegate: AnyObject {
    func addNewContent(_ cell: AddNewDataTableViewCell)
    func getInputTextField(indexPath: IndexPath, textField: String)
    func getTitle(indexPath: IndexPath, title: String)
}

class AddNewDataTableViewCell: UITableViewCell {
    weak var delegate: AddNewDataTableViewCellDelegate?
    var costContent: [String] = ["早餐", "午餐", "晚餐"]
    var accountContent: [String] = ["現金", "信用卡", "悠遊卡"]
    // 宣告一個pickerView
    let contentPicker = UIPickerView()
    // 宣告一個alertVC
    var controller = UIAlertController()
    var segmentTag = 0
    var indexPath: IndexPath? {
        didSet {
            // 第一個金額cell不需要picker，因此讓他顯示數字鍵盤
            if indexPath?.item == 0 {
                addNewContentBO.isHidden = true
                // contentTextField有更動時叫出黑色數字鍵盤
                contentTextField.keyboardType = .numberPad
                contentTextField.keyboardAppearance = .dark
                return
            } else {
                // picker delegate & datasource
                addNewContentBO.isHidden = false
                // 種類、帳戶需要picker，故執行picker功能
                contentPicker.delegate = self
                contentPicker.dataSource = self
                contentTextField.inputView = contentPicker
                contentTextField.keyboardAppearance = .dark
            }
        }
    }

    @IBOutlet weak var contentTextField: UITextField! {
        didSet {
            contentTextField.delegate = self
        }
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addNewContentBO: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    // name: 金額、種類、帳戶, content: 種類內容 - 生成tableview時覆用
// MARK: - Notice
    func fillInContent(name: String) {
        titleLabel.text = name
        contentTextField.text = ""
    }

// MARK: - picker
    func contentConfig(segment: Int) {
        controller = UIAlertController(title: "新增選項", message: "", preferredStyle: .alert)
        controller.addTextField { textField in
            textField.placeholder = "內容"
            textField.keyboardType = UIKeyboardType.default
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { [unowned controller] _ in
            // 利用index.item（點選到的是哪一個add button）來更新對應的array資料並reload component
            if segment == 2 {
                    self.accountContent.append(controller.textFields?[0].text ?? "")
                    // 按下ok之後同步reload picker的component
                    self.contentPicker.reloadAllComponents()
            } else {
                if self.indexPath?.item == 1 {
                    self.costContent.append(controller.textFields?[0].text ?? "")
                    // 按下ok之後同步reload picker的component
                    self.contentPicker.reloadAllComponents()
                } else {
                    self.accountContent.append(controller.textFields?[0].text ?? "")
                    // 按下ok之後同步reload picker的component
                    self.contentPicker.reloadAllComponents()
                }
            }
        }

        controller.addAction(okAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        controller.addAction(cancelAction)

        addNewContentBO.addTarget(self, action: #selector(didSelectAddButton), for: .touchUpInside)
    }

    @objc func didSelectAddButton() {
        // 按下add button後把最新選項用delegate傳給VC
        self.delegate?.addNewContent(self)
    }
}

// MARK: - picker
extension AddNewDataTableViewCell: UIPickerViewDelegate, UIPickerViewDataSource {
    // 有幾列可以選擇
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    // 每列有多少行資料
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch indexPath?.item {
        case 1:
            if segmentTag == 2 {
                return accountContent.count
            } else {
                return costContent.count
            }
        case 2:
            return accountContent.count
        default:
            return 0
        }
    }

    // 每個選項顯示的資料, Inherited from UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch indexPath?.item {
        case 1:
            if segmentTag == 2 {
                return accountContent[row]
            } else {
                return costContent[row]
            }
        case 2:
            return accountContent[row]
        default:
            return nil
        }
    }

    // pickerView改變選擇後執行的動作, Inherited from UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // 將 UITextField 的值更新為 array 的第 row 項資料
        switch indexPath?.item {
        case 1:
            if segmentTag == 2 {
                contentTextField.text = accountContent[row]
            } else {
                contentTextField.text = costContent[row]
            }
        case 2:
            contentTextField.text = accountContent[row]
        default:
            return
        }
    }
}

// textField delegate
extension AddNewDataTableViewCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if indexPath?.section != 0 {
            print("====== TF delegate \(contentTextField.text)")
        }
        self.delegate?.getInputTextField(indexPath: self.indexPath ?? [0, 0], textField: textField.text ?? "")

        self.delegate?.getTitle(indexPath: self.indexPath ?? [0, 0], title: self.titleLabel.text ?? "")
    }
}
