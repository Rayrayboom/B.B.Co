//
//  CoDetailTableViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/10.
//

import UIKit
import FirebaseFirestore
import SwiftUI

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
            switch indexPath?.section {
            case 3:
                // picker delegate & datasource
                // 付款者需要picker，故執行picker功能
                contentPicker.delegate = self
                contentPicker.dataSource = self
                contentTextField.inputView = contentPicker
                contentTextField.keyboardAppearance = .dark
                return
            case 2:
                // contentTextField有更動時叫出黑色文字鍵盤
                contentTextField.keyboardType = .numberPad
                contentTextField.keyboardAppearance = .dark
            default:
                // contentTextField有更動時叫出黑色數字鍵盤
                contentTextField.keyboardType = .namePhonePad
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
        case 3:
            return content.count
        default:
            return 0
        }
    }

    // 每個選項顯示的資料, Inherited from UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch indexPath?.section {
        case 3:
            return content[row]
        default:
            return nil
        }
    }

    // pickerView改變選擇後執行的動作, Inherited from UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch indexPath?.section {
        case 3:
            contentTextField.text = content[row]
        default:
            return
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
