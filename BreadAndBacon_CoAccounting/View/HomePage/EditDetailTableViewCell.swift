//
//  EditDetailTableViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/4.
//

import UIKit

protocol EditDetailTableViewCellDelegate: AnyObject {
    func getDetail(detail: String)
}

class EditDetailTableViewCell: UITableViewCell {
    weak var delegate: EditDetailTableViewCellDelegate?

    @IBOutlet weak var detailTextView: UITextView!
    override func awakeFromNib() {
        detailTextView.delegate = self
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

// textView delegate
extension EditDetailTableViewCell: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        self.delegate?.getDetail(detail: detailTextView.text)
    }
}
