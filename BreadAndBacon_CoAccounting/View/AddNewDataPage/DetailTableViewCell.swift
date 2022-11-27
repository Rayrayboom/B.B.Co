//
//  DetailTableViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/2.
//

import UIKit

protocol DetailTableViewCellDelegate: AnyObject {
    func getDetail(detail: String)
}

class DetailTableViewCell: UITableViewCell {
    weak var delegate: DetailTableViewCellDelegate?

    @IBOutlet weak var detailTextView: UITextView! {
        didSet {
            detailTextView.delegate = self
            // contentTextField有更動時叫出黑色數字鍵盤
//            detailTextView.becomeFirstResponder()
            detailTextView.keyboardAppearance = .dark
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // 設定textField外觀
        detailTextView.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        detailTextView.layer.borderWidth = 1
        detailTextView.layer.borderColor = CGColor.init(red: 189/255, green: 189/255, blue: 190/255, alpha: 1)
        detailTextView.layer.cornerRadius = 5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

// textView delegate
extension DetailTableViewCell: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        self.delegate?.getDetail(detail: detailTextView.text)
    }
}
