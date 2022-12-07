//
//  AddDateTableViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/2.
//

import UIKit

protocol AddDateTableViewCellDelegate: AnyObject {
    func getDate(_ cell: AddDateTableViewCell, sender: UIDatePicker)
    func getMonth(_ cell: AddDateTableViewCell, sender: UIDatePicker)
}

class AddDateTableViewCell: UITableViewCell {
    weak var delegate: AddDateTableViewCellDelegate?

    @IBOutlet weak var addDatePicker: UIDatePicker!

    override func awakeFromNib() {
        super.awakeFromNib()
        addDatePicker.tintColor = .systemBrown
        // 設定cell color
        self.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    // 點選cell的datePicker時給值，回傳給homeVC的data.dateTime & data.monthTime
    func config() {
        addDatePicker.addTarget(self, action: #selector(didSelectData(_:)), for: .valueChanged)
    }

    @objc func didSelectData(_ sender: UIDatePicker) {
        delegate?.getDate(self, sender: sender)
        delegate?.getMonth(self, sender: sender)
    }
}
