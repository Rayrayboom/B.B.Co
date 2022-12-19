//
//  EditTimeTableViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/4.
//

import UIKit

protocol EditTimeTableViewCellDelegate: AnyObject {
    func getDate(_ cell: EditTimeTableViewCell, sender: UIDatePicker)
}

class EditTimeTableViewCell: UITableViewCell {
    weak var delegate: EditTimeTableViewCellDelegate?

    @IBOutlet weak var editDatePicker: UIDatePicker!
    override func awakeFromNib() {
        super.awakeFromNib()
        editDatePicker.tintColor = .systemBrown
        self.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

    func config(dateTime: String) {
        editDatePicker.addTarget(self, action: #selector(didSelectData(_:)), for: .valueChanged)
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
        editDatePicker.date = BBCDateFormatter.shareFormatter.date(from: dateTime) ?? Date()
    }
    
    @objc func didSelectData(_ sender: UIDatePicker) {
        delegate?.getDate(self, sender: sender)
    }
}
