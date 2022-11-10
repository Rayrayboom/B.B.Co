//
//  CoDetailTableViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/10.
//

import UIKit
import FirebaseFirestore

protocol CoDetailTableViewCellDelegate: AnyObject {
    func getInputTextField(indexPath: IndexPath, textField: String)
}

class CoDetailTableViewCell: UITableViewCell {
    weak var delegate: CoDetailTableViewCellDelegate?

    var content: [String] = []
    // 宣告一個pickerView
    let contentPicker = UIPickerView()
    var indexPath: IndexPath? {
        didSet {
            // 第一個品項cell(section 1)不需要picker，因此讓他顯示數字鍵盤
            if indexPath?.section == 1 {
                // contentTextField有更動時叫出黑色數字鍵盤
                contentTextField.keyboardType = .namePhonePad
                contentTextField.keyboardAppearance = .dark
                return
            } else {
                // picker delegate & datasource
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

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

// MARK: - picker
extension CoDetailTableViewCell: UIPickerViewDelegate, UIPickerViewDataSource {
    // 有幾列可以選擇
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    // 每列有多少行資料
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch indexPath?.section {
        case 1:
            return 0
        default:
            return content.count
        }
    }

    // 每個選項顯示的資料, Inherited from UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch indexPath?.section {
        case 1:
            return nil
        default:
            return content[row]
        }
    }

    // pickerView改變選擇後執行的動作, Inherited from UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch indexPath?.section {
        case 1:
            return
        default:
            contentTextField.text = content[row]
        }
    }
}

// textField delegate
extension CoDetailTableViewCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.delegate?.getInputTextField(indexPath: self.indexPath ?? [0, 0], textField: textField.text ?? "")
        print("====== co delegate \(contentTextField.text)")
    }
}
