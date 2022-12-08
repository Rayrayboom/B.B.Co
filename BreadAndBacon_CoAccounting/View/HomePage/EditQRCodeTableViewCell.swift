//
//  EditQRCodeTableViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/4.
//

import UIKit

class EditQRCodeTableViewCell: UITableViewCell {

    @IBOutlet weak var qrButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // cell color
        self.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
