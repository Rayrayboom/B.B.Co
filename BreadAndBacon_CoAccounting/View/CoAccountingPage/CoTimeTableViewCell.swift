//
//  coTimeTableViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/10.
//

import UIKit

protocol CoTimeTableViewCellDelegate: AnyObject {
    func getDate(_ cell: CoTimeTableViewCell, sender: UIDatePicker)
    func getMonth(_ cell: CoTimeTableViewCell, sender: UIDatePicker)
}

class CoTimeTableViewCell: UITableViewCell {
    weak var delegate: CoTimeTableViewCellDelegate?

    @IBOutlet weak var datePicker: UIDatePicker!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func config() {
        datePicker.addTarget(self, action: #selector(didSelectDate(_:)), for: .valueChanged)
    }

    @objc func didSelectDate(_ sender: UIDatePicker) {
        // date delegate
        self.delegate?.getDate(self, sender: sender)
        // month delegate
        self.delegate?.getMonth(self, sender: sender)
    }
}
