//
//  QRCodeViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/31.
//

import UIKit

import AVFoundation
import Vision
import VisionKit

class QRCodeViewController: UIViewController {
    var content: String = ""

//    @IBOutlet weak var contentLabel: UILabel!
//    @IBAction func scanQRCode(_ sender: UIButton) {
//        let documentCameraViewController = VNDocumentCameraViewController()
//        documentCameraViewController.delegate = self
//        present(documentCameraViewController, animated: true)
//        contentLabel.text = ""
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func processImage(image: UIImage) {
        guard let cgImage = image.cgImage else {
            return
        }
        let handler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNDetectBarcodesRequest { request, error in
            if let observation = request.results?.first as? VNBarcodeObservation,
               observation.symbology == .qr {
                print("詳細資訊如下：\(observation.payloadStringValue ?? "")")
//                self.contentLabel.text = observation.payloadStringValue ?? ""
//                self.content.append(observation.payloadStringValue ?? "")
                self.content = observation.payloadStringValue ?? ""
                print("發票號碼：\(self.content.prefix(10))")
                print("品項：\((self.content as NSString).substring(with: NSMakeRange(150, 160)))")
            }
        }
//        request.regionOfInterest = CGRect(x: 1, y: 1, width: 1, height: 1)
        do {
            try handler.perform([request])
            print("this is request \(request)")
        } catch {
            print(error)
        }
    }
}

extension QRCodeViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        print("=== in delegate")
        let image = scan.imageOfPage(at: scan.pageCount - 1)
        processImage(image: image)
        dismiss(animated: true, completion: nil)
    }
}
