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
            detailTextView.keyboardAppearance = .dark
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        detailTextView.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        detailTextView.layer.borderWidth = 1
        detailTextView.layer.borderColor = CGColor.init(red: 189/255, green: 189/255, blue: 190/255, alpha: 1)
        detailTextView.layer.cornerRadius = 5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

    override func prepareForReuse() {
        super.prepareForReuse()
        detailTextView.text = ""
    }

    func config(detailText: String) {
        detailTextView.text = detailText
    }
}

extension DetailTableViewCell: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        self.delegate?.getDetail(detail: detailTextView.text)
    }
}
