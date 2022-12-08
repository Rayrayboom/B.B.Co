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
        // 設定cell color
        self.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        // 設定textField外觀
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
        // 每次新生成時，detailTextView要先清空
        detailTextView.text = ""
    }
    
    // 配置textView
    func config(detailText: String) {
        // 發票detail資料要塞進data.detailTextField才會真的吃到資料
        detailTextView.text = detailText
    }
}

// textView delegate
extension DetailTableViewCell: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        self.delegate?.getDetail(detail: detailTextView.text)
    }
}
