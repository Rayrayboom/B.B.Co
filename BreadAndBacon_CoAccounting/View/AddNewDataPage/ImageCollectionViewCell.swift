//
//  ImageCollectionViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/22.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    static let identifier = "imageCollectionCell"
    static func nib() -> UINib {
        return UINib(nibName: "ImageCollectionViewCell", bundle: nil)
    }

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var didSelectView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    public func configure(with model: Model) {
        self.label.text = model.text
        self.imageView.image = UIImage(named: model.imageName)
    }
}
