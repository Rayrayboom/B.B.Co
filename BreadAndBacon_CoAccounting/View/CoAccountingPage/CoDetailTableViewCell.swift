//
//  CoDetailTableViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/10.
//

import UIKit

protocol CoDetailTableViewCellDelegate: AnyObject {
    func getInputTextField(indexPath: IndexPath, textField: String)
    func addNewContent(_ cell: CoDetailTableViewCell, indexPathItem: Int)
}

class CoDetailTableViewCell: UITableViewCell {
    weak var delegate: CoDetailTableViewCellDelegate?

    var content: [String] = []
    let contentPicker = UIPickerView()
    var presentCalculateVC: CalculateViewController?
    var indexPath: IndexPath? {
        didSet {
            switch indexPath?.section {
            case 3:
                contentPicker.delegate = self
                contentPicker.dataSource = self
                contentTextField.inputView = contentPicker
                contentTextField.keyboardAppearance = .dark
                return
            case 2:
                contentTextField.inputView = UIView.init(frame: CGRect.zero)
                contentTextField.inputAccessoryView = UIView.init(frame: CGRect.zero)
            default:
                contentTextField.keyboardType = .namePhonePad
                contentTextField.keyboardAppearance = .dark
            }
        }
    }

    @IBOutlet weak var contentTextField: UITextField! {
        didSet {
            contentTextField.delegate = self
            contentTextField.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
            contentTextField.layer.borderWidth = 1
            contentTextField.layer.borderColor = CGColor.init(red: 189/255, green: 189/255, blue: 190/255, alpha: 1)
            contentTextField.layer.cornerRadius = 5
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
}

extension CoDetailTableViewCell: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch indexPath?.section {
        case 3:
            return content.count
        default:
            return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch indexPath?.section {
        case 3:
            return content[row]
        default:
            return nil
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch indexPath?.section {
        case 3:
            contentTextField.text = content[row]
        default:
            return
        }
    }
}

extension CoDetailTableViewCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch indexPath?.section {
        case 1:
            return
        case 2:
            let addNewDataStoryboard = UIStoryboard(name: "AddNewData", bundle: nil)
            presentCalculateVC = addNewDataStoryboard.instantiateViewController(withIdentifier: "calculateVC") as? CalculateViewController
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
    }
}
