//
//  QRCodeViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/31.
//

import UIKit
import AVFoundation

// QRCode掃描後的內容以protocol-delegate傳給addNewData page_detail cell
protocol QRCodeViewControllerDelegate: AnyObject {
    func getMessage(message: String)
    func getInvDetail(didGet items: Invoice)
    func getInvDetail(didFailwith error: Error)
}

class QRCodeViewController: UIViewController {
    weak var delegate: QRCodeViewControllerDelegate?

    var content: String = ""

    // For QRCode Scanner
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    var controller = UIAlertController()

    @IBOutlet weak var messageLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        scanQRCode()
    }

    func scanQRCode() {
        // 取得後置鏡頭來擷取影片
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get the camera device")
            return
        }

        do {
            // 使用前一個裝置物件來取得 AVCaptureDeviceInput 類別的實例
            let input = try AVCaptureDeviceInput(device: captureDevice)
            // 在擷取 session 設定輸入裝置
            captureSession.addInput(input)

            // 初始化一個 AVCaptureMetadataOutput 物件並將其設定做為擷取 session 的輸出裝置
            let captureMetadataOutput = AVCaptureMetadataOutput()

            // TODO: 針對特定區域掃描(待研究方框位置)
//            captureMetadataOutput.rectOfInterest = CGRect(x: 0.0, y: 0.0, width: 5.0, height: 1.0)

            captureSession.addOutput(captureMetadataOutput)
            // 設定委派並使用預設的調度佇列來執行回呼（call back）
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]

            // 初始化影片預覽層，並將其作為子層加入 viewPreview 視圖的圖層中
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)

            // 開始影片的擷取
            captureSession.startRunning()

            // 移動訊息標籤與頂部列至上層
            view.bringSubviewToFront(messageLabel)
//            view.bringSubviewToFront(topbar)

            // 初始化 QR Code 框來突顯 QR code
            qrCodeFrameView = UIView()

            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubviewToFront(qrCodeFrameView)
            }
        } catch {
            // 假如有錯誤產生、單純輸出其狀況不再繼續執行
            print(error)
            return
        }
    }

    func contentConfig() {
        captureSession.stopRunning()
        // 執行delegate + 塞掃描內容
        self.delegate?.getMessage(message: messageLabel.text ?? "")
//        print(messageLabel.text)

        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    // 解析invoice data
    func decodeInvoice(message: String) {
        let invNum = message.prefix(10)
        let encrypt = message.prefix(24)
        var invYear = (message as NSString).substring(with: NSMakeRange(10, 3))
        var translateYear = (Int(invYear) ?? 0) + 1911
        invYear = String(translateYear)

        let invMonth = (message as NSString).substring(with: NSMakeRange(13, 2))
        let invDay = (message as NSString).substring(with: NSMakeRange(15, 2))
        let randomNumber = (message as NSString).substring(with: NSMakeRange(17, 4))
        let sellerID = (message as NSString).substring(with: NSMakeRange(45, 8))

        // POST API
        sendInvoiceAPI(invNum: String(invNum), invDate: "\(invYear)/\(invMonth)/\(invDay)", encrypt: String(encrypt), sellerID: sellerID, randomNumber: randomNumber)

        print("invNum", invNum)
        print("encrypt", encrypt)
        print("invYear", invYear)
        print("invMonth", invMonth)
        print("invDay", invDay)
        print("randomNumber", randomNumber)
        print("sellerID", sellerID)
    }

    // POST API and parse data
    func sendInvoiceAPI(invNum: String, invDate: String, encrypt: String, sellerID: String, randomNumber: String) {
        let url = URL(string: "https://api.einvoice.nat.gov.tw/PB2CAPIVAN/invapp/InvApp?version=0.6&type=QRCode&invNum=\(invNum)&action=qryInvDetail&generation=V2&invDate=\(invDate)&encrypt=\(encrypt)&sellerID=\(sellerID)&UUID=10000&randomNumber=\(randomNumber)&appID=EINV0202210362275")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request, completionHandler: {(data, response, error) in
            if let error = error {
                self.delegate?.getInvDetail(didFailwith: error)
                print(error)
                return
            }

            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200 else {
                print("response error")
                return
            }

            if let data = data {
                if let detail = self.parseData(jsonData: data) {
                    self.delegate?.getInvDetail(didGet: detail)
                }
            }
        })
        task.resume()
    }

    func parseData(jsonData: Data) -> Invoice? {
        do {
            let result = try JSONDecoder().decode(Invoice.self, from: jsonData)
            // 測試看是否有抓到資料
            print("=== result is \(jsonData)")
            return result
        }catch {
            delegate?.getInvDetail(didFailwith: error)
            print("result error")
            return nil
        }
    }

    // 掃到資料後跳出提醒顯示內容
//    func alert() {
//        controller = UIAlertController(title: "發票內容", message: "", preferredStyle: .alert)
//        controller.addTextField { textField in
//            textField.placeholder = "內容"
//            textField.keyboardType = UIKeyboardType.default
//        }
//        // 按下OK執行的動作
//        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
////            self.delegate?.getContent(content: self.messageLabel.text ?? "")
//            print(self.messageLabel.text ?? "")
//        }
//
//        controller.addAction(okAction)
//        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
//        controller.addAction(cancelAction)
//        present(controller, animated: true)
//    }
}

extension QRCodeViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // 檢查  metadataObjects 陣列為非空值，它至少需包含一個物件
        if metadataObjects.isEmpty {
            qrCodeFrameView?.frame = CGRect.zero
            messageLabel.text = "No QR code is detected"
            return
        }

        // 取得元資料（metadata）物件
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject

        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            // 倘若發現的元資料與 QR code 元資料相同，便更新狀態標籤的文字並設定邊界
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds

            if metadataObj.stringValue != nil {
                // 掃描後拿到的invoice亂碼
                messageLabel.text = metadataObj.stringValue
                // 用delegate把data給addNewDataVC
                contentConfig()
                // 解析invoice data
                decodeInvoice(message: messageLabel.text ?? "")
//                alert()
            }
        }
    }
}
