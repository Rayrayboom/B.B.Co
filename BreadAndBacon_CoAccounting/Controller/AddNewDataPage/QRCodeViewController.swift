//
//  QRCodeViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/31.
//

import UIKit
import AVFoundation

protocol QRCodeViewControllerDelegate: AnyObject {
    func getMessage(message: String)
}

class QRCodeViewController: UIViewController {
    weak var delegate: QRCodeViewControllerDelegate?
    var content: String = ""
    // For QRCode Scanner
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
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

            let scanRectTransformed = CGRect(x: 0.33, y: 0.5, width: 0.16, height: 0.25)

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
            
            // 加上黃偵測方框
            scanAreaView = UIView()
            if let scanAreaView = scanAreaView {
                scanAreaView.layer.borderColor = UIColor().hexStringToUIColor(hex: "E5BB4B").cgColor
                scanAreaView.layer.borderWidth = 4
                scanAreaView.frame = CGRect(x: 90, y: 300, width: 100, height: 100)
                view.addSubview(scanAreaView)
                view.bringSubviewToFront(scanAreaView)
            }
            
            // 加上灰偵測方框
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
            // 假如有錯誤產生、單純輸出其狀況則不再繼續執行
            print(error)
            return
        }
    }

    // 停止偵測 + dismissQRCodeVC
    func dismissQRCodeVC() {
        captureSession.stopRunning()
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
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
            // 倘若發現的元資料與QR code元資料相同，便更新狀態標籤的文字並設定邊界
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            print("=== this is green frame", qrCodeFrameView?.frame)
            print("=== this is screen", UIScreen.main.bounds)

            if metadataObj.stringValue != nil {
                // 掃描後拿到的invoice亂碼
                messageLabel.text = metadataObj.stringValue
                // 把亂碼傳給aadNewDataVC
                self.delegate?.getMessage(message: metadataObj.stringValue ?? "")
                // 取得亂碼後停止偵測 + dismissQRCodeVC
                dismissQRCodeVC()
            }
        }
    }
}
