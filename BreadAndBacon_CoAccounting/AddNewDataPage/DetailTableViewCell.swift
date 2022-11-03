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
        // Initialization code
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
