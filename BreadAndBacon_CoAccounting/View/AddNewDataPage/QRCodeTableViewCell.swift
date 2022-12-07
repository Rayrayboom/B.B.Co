//
//  QRCodeTableViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/2.
//

import UIKit

class QRCodeTableViewCell: UITableViewCell {

    @IBOutlet weak var qrButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // 設定cell color
        self.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
