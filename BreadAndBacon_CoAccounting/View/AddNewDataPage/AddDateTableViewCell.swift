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
        self.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func config(currentDate: String) {
        addDatePicker.addTarget(self, action: #selector(didSelectData(_:)), for: .valueChanged)
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
        addDatePicker.date = BBCDateFormatter.shareFormatter.date(from: currentDate) ?? Date()
    }

    @objc func didSelectData(_ sender: UIDatePicker) {
        delegate?.getDate(self, sender: sender)
        delegate?.getMonth(self, sender: sender)
    }
}
