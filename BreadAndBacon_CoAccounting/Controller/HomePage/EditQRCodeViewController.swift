//
//  EditQRCodeViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/9.
//

import UIKit
import AVFoundation

// QRCode掃描後的內容以protocol-delegate傳給addNewData page_detail cell
protocol EditQRCodeViewControllerDelegate: AnyObject {
    func getMessage(message: String)
    func getInvDetail(didGet items: Invoice)
    func getInvDetail(didFailwith error: Error)
}

class EditQRCodeViewController: UIViewController {
    weak var delegate: EditQRCodeViewControllerDelegate?

    var content: String = ""

    // For QRCode Scanner
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    let controller = UIAlertController()
    var scanAreaView: UIView?
    var mockAreaView: UIView?

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
            
            // 開始影片的擷取
            self.captureSession.startRunning()
            
            // TODO: 針對特定區域掃描(待研究方框位置)
            let size = 300
            let screenWidth = self.view.frame.size.width
            print("=== this is screen", view.frame.size)
            let xPos = (CGFloat(screenWidth) / CGFloat(2)) - (CGFloat(size) / CGFloat(2))
            print("=== this is xPos", xPos)
            let scanRect = CGRect(x: Int(xPos), y: 150, width: size, height: size)
            print("=== this is scanRect", scanRect)
            var x = scanRect.origin.x/480
            var y = scanRect.origin.y/640
            var width = scanRect.width/480
            var height = scanRect.height/640
//            var scanRectTransformed = CGRect(x: x, y: y, width: width, height: height)
            var scanRectTransformed = CGRect(x: 0.33, y: 0.5, width: 0.16, height: 0.25)
            print("=== this is scanRect.origin.x", scanRect.origin)
            print("=== this is view.center.x", view.center.x)
            print("=== this is view.center.y", view.center.y)
            print("=== this is scanRectTransformed", scanRectTransformed)
            
            captureSession.addOutput(captureMetadataOutput)
            // 設定委派並使用預設的調度佇列來執行回呼（call back）
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]

            // 初始化影片預覽層，並將其作為子層加入 viewPreview 視圖的圖層中
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            captureMetadataOutput.rectOfInterest = scanRectTransformed
            view.layer.addSublayer(videoPreviewLayer!)

            // 移動訊息標籤與頂部列至上層
            view.bringSubviewToFront(messageLabel)
            
            // 加上黃色偵測方框
            scanAreaView = UIView()
            if let scanAreaView = scanAreaView {
                scanAreaView.layer.borderColor = UIColor().hexStringToUIColor(hex: "E5BB4B").cgColor
                scanAreaView.layer.borderWidth = 4
                scanAreaView.frame = CGRect(x: 90, y: 300, width: 100, height: 100)
                view.addSubview(scanAreaView)
                view.bringSubviewToFront(scanAreaView)
            }
            
            // 加上黃色偵測方框
            mockAreaView = UIView()
            if let mockAreaView = mockAreaView {
                mockAreaView.layer.borderColor = UIColor.lightGray.cgColor
                mockAreaView.layer.borderWidth = 4
                mockAreaView.frame = CGRect(x: 210, y: 300, width: 100, height: 100)
                view.addSubview(mockAreaView)
                view.bringSubviewToFront(mockAreaView)
            }

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
        DispatchQueue.main.async {
            self.delegate?.getMessage(message: self.messageLabel.text ?? "")
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
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
        let url = URL(string: "https://api.einvoice.nat.gov.tw/PB2CAPIVAN/invapp/InvApp?version=0.6&type=QRCode&invNum=\(invNum)&action=qryInvDetail&generation=V2&invDate=\(invDate)&encrypt=\(encrypt)&sellerID=\(sellerID)&UUID=\(APIKey.invoiceUUID)&randomNumber=\(randomNumber)&appID=\(APIKey.QRAppID)")
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
//    }
}

extension EditQRCodeViewController: AVCaptureMetadataOutputObjectsDelegate {
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
                messageLabel.text = metadataObj.stringValue
                contentConfig()
                // 解析invoice data
                decodeInvoice(message: messageLabel.text ?? "")
//                alert()
            }
        }
    }
}
