//
//  CoBookTableViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/11.
//

import UIKit

class CoBookTableViewCell: UITableViewCell {
    @IBOutlet weak var bookNameLabel: UILabel!
    @IBOutlet weak var roomIDLabel: UILabel!
    @IBOutlet weak var coImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
}
