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
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
