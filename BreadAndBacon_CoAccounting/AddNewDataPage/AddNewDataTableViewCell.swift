//
//  AddNewDataTableViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/30.
//

import UIKit

class AddNewDataTableViewCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentTextField: UITextField!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var categoryResultLabel: UILabel!
    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet weak var detailTextView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // 金額、種類、帳戶function - 生成tableview時覆用
    func fillInContent(name: String) {
        titleLabel.text = name
        contentTextField.text = ""
    }
}
