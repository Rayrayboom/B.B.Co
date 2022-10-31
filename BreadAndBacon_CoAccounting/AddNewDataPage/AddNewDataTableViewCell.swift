//
//  AddNewDataTableViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/30.
//

import UIKit

protocol PassTextfieldDelegate: AnyObject {
    func passTextField(_ cell: AddNewDataTableViewCell, sender: UIDatePicker)
}

class AddNewDataTableViewCell: UITableViewCell {
    weak var delegate: PassTextfieldDelegate?

    @IBOutlet weak var dateTextfield: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentTextField: UITextField!
    @IBOutlet weak var qrButton: UIButton!
    @IBAction func insertQRCode(_ sender: UIButton) {
    }
    @IBOutlet weak var detailTextView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

    // 金額、種類、帳戶function - 生成tableview時覆用
    func fillInContent(name: String) {
        titleLabel.text = name
        contentTextField.text = ""
    }

    // cell本身不執行func，只在這邊設定完之後交由delegate傳過去給VC動作
    // 把datePicker相關動作移回來是因為addTarget的self指的是當前的VC裡的func，在addNewDataVC執行addTarget會報錯的原因在於self在addNewDataVC中其實會找不到dateTextfield這個東西，會無法給值; 因此需要用一個config func讓addTarget抓到cell本身的func且拿到對應dateTextfield，才有辦法把sender的值用delegate倒給addNewDataVC去塞值
    func config(dateStr: String) {
        self.dateTextfield.text = dateStr
        self.dateTextfield.textColor = .link
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
}
