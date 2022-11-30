//
//  EditTimeTableViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/4.
//

import UIKit

class EditTimeTableViewCell: UITableViewCell {
    @IBOutlet weak var editDatePicker: UIDatePicker!
    override func awakeFromNib() {
        super.awakeFromNib()
        editDatePicker.tintColor = .systemBrown
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
