//
//  UIiImageAndStringTracfermation + Extension.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/22.
//

import Foundation
import UIKit

// image轉string
extension UIImage {
    // PNG轉string
    func toPngString() -> String? {
        let data = self.pngData()
        return data?.base64EncodedString(options: .endLineWithLineFeed)
    }

    // JPEG轉string
    func toJpegString(compressionQuality cq: CGFloat) -> String? {
        let data = self.jpegData(compressionQuality: cq)
        return data?.base64EncodedString(options: .endLineWithLineFeed)
    }
}

// string轉image
extension String {
    func toImage() -> UIImage? {
        if let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters){
            return UIImage(data: data)
        }
        return nil
    }
}
