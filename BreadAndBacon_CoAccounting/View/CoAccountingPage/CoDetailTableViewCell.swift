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
    func addNewContent(_ cell: CoDetailTableViewCell, indexPathItem: Int)
}

class CoDetailTableViewCell: UITableViewCell {
    weak var delegate: CoDetailTableViewCellDelegate?

    var content: [String] = []
    // 宣告一個pickerView
    let contentPicker = UIPickerView()
    // calculator VC
    var presentCalculateVC: CalculateViewController?
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
                // 隱藏IQKeyBoard自動帶出的鍵盤
                contentTextField.inputView = UIView.init(frame: CGRect.zero)
                contentTextField.inputAccessoryView = UIView.init(frame: CGRect.zero)
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
            // 設定textField外觀
            contentTextField.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
            contentTextField.layer.borderWidth = 1
            contentTextField.layer.borderColor = CGColor.init(red: 189/255, green: 189/255, blue: 190/255, alpha: 1)
            contentTextField.layer.cornerRadius = 5
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
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch indexPath?.section {
        case 1:
            return
        case 2:
            // 讓amount textField一點進去就直接顯示計算機
            let addNewDataStoryboard = UIStoryboard(name: "AddNewData", bundle: nil)
            presentCalculateVC = addNewDataStoryboard.instantiateViewController(withIdentifier: "calculateVC") as! CalculateViewController
            presentCalculateVC?.modalPresentationStyle = .overCurrentContext
            self.delegate?.addNewContent(self, indexPathItem: indexPath?.item ?? 0)

            presentCalculateVC?.closure = {[weak self] text in
                if self?.contentTextField.text == "" {
                    self?.contentTextField.text = text
                    self?.delegate?.getInputTextField(indexPath: self?.indexPath ?? [0, 0], textField: textField.text ?? "")
                } else {
                    self?.contentTextField.text = text
                    self?.delegate?.getInputTextField(indexPath: self?.indexPath ?? [0, 0], textField: textField.text ?? "")
                }
            }
        case 3:
            contentTextField.text = content[0]
        default:
            return
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.delegate?.getInputTextField(indexPath: self.indexPath ?? [0, 0], textField: textField.text ?? "")
        print("====== co delegate \(contentTextField.text)")
    }
}
