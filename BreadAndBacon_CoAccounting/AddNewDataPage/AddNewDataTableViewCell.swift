//
//  AddNewDataTableViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/30.
//

import UIKit

protocol PassTextfieldDelegate: AnyObject {
    func passTextField(_ cell: AddNewDataTableViewCell, sender: UIDatePicker)
    func addNewContent(_ cell: AddNewDataTableViewCell)
}

class AddNewDataTableViewCell: UITableViewCell {
    weak var delegate: PassTextfieldDelegate?
    var costContent: [String] = ["早餐", "午餐", "晚餐"]
    var accountContent: [String] = ["現金", "信用卡", "悠遊卡"]
    // 宣告一個pickerView
    let contentPicker = UIPickerView()
    // 宣告一個alertVC
    var controller = UIAlertController()
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
// MARK: - picker
                addNewContentBO.isHidden = false
                // 種類、帳戶需要picker，故執行picker功能
//                let contentPicker = UIPickerView()
                contentPicker.delegate = self
                contentPicker.dataSource = self
                contentTextField.inputView = contentPicker
                contentTextField.keyboardAppearance = .dark
            }
        }
    }

    @IBOutlet weak var contentTextField: UITextField!
    @IBOutlet weak var dateTextfield: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addNewContentBO: UIButton!
    @IBOutlet weak var qrButton: UIButton!
    @IBOutlet weak var detailTextView: UITextView! {
        didSet {
            // contentTextField有更動時叫出黑色數字鍵盤
//            detailTextView.becomeFirstResponder()
            detailTextView.keyboardAppearance = .dark
        }
    }

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

    // cell本身不執行func，只在這邊設定完之後交由delegate傳過去給VC動作
    // 把datePicker相關動作移回來是因為addTarget的self指的是當前的VC裡的func，在addNewDataVC執行addTarget會報錯的原因在於self在addNewDataVC中其實會找不到dateTextfield這個東西，會無法給值; 因此需要用一個config func讓addTarget抓到cell本身的func且拿到對應dateTextfield，才有辦法把sender的值用delegate倒給addNewDataVC去塞值
    func config(dateStr: String) {
        self.dateTextfield.text = dateStr
        self.dateTextfield.textColor = .black
        self.dateTextfield.textAlignment = .center
        self.dateTextfield.keyboardAppearance = .dark
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(didSelectData(_:)), for: UIControl.Event.valueChanged)
        datePicker.frame.size = CGSize(width: 0, height: 200)
        self.dateTextfield.inputView = datePicker
    }

    // 利用addNewDataTableViewCell自己的delegate傳值過去給addNewDataVC來執行塞值的動作
    @objc func didSelectData(_ sender: UIDatePicker) {
        self.delegate?.passTextField(self, sender: sender)
    }

// MARK: - picker
    func contentConfig() {
        controller = UIAlertController(title: "新增選項", message: "", preferredStyle: .alert)
        controller.addTextField { textField in
            textField.placeholder = "內容"
            textField.keyboardType = UIKeyboardType.default
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { [unowned controller] _ in
            // 利用index.item（點選到的是哪一個add button）來更新對應的array資料並reload component
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

        controller.addAction(okAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        controller.addAction(cancelAction)

        addNewContentBO.addTarget(self, action: #selector(didSelectAddButton), for: .touchUpInside)
    }

    @objc func didSelectAddButton() {
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
            return costContent.count
        default:
            return accountContent.count
        }
    }

    // 每個選項顯示的資料, Inherited from UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch indexPath?.item {
        case 1:
            return costContent[row]
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
            contentTextField.text = costContent[row]
        default:
            contentTextField.text = accountContent[row]
        }
        // reload當前選項所有的pickerView
//        pickerView.reloadAllComponents()
    }
}
