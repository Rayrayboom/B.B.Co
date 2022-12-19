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
        super.awakeFromNib()
        detailTextView.delegate = self
        self.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        detailTextView.keyboardAppearance = .dark
        detailTextView.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        detailTextView.layer.borderWidth = 1
        detailTextView.layer.borderColor = CGColor.init(red: 189/255, green: 189/255, blue: 190/255, alpha: 1)
        detailTextView.layer.cornerRadius = 5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

    func config(detailText: String) {
        detailTextView.text = detailText
    }
}

extension EditDetailTableViewCell: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        self.delegate?.getDetail(detail: detailTextView.text)
    }
}
