//
//  AddNewDataTableViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/30.
//

import UIKit
import FirebaseFirestore
import SwiftKeychainWrapper

protocol AddNewDataTableViewCellDelegate: AnyObject {
    func addNewContent(_ cell: AddNewDataTableViewCell)
    func getInputTextField(indexPath: IndexPath, textField: String)
    func getTitle(indexPath: IndexPath, title: String)
    func setContent(content: [String])
    func getImageName(indexPath: IndexPath, imageName: String)
}

class AddNewDataTableViewCell: UITableViewCell {
    weak var delegate: AddNewDataTableViewCellDelegate?
    // 用來存取對應content array（由VC判斷當前是哪一個indexPath.row來決定content array要放costContent或accountContent）
    var content: [String] = []
    // 用來存image的array
    var imageArr: [UIImage?] = []
    // 宣告一個pickerView
    let contentPicker = UIPickerView()
    // 宣告一個alertVC
    var controller = UIAlertController()
    var segmentTag = 0
    var indexPath: IndexPath? {
        didSet {
            // 第一個金額cell不需要picker，因此讓他顯示數字鍵盤
            if indexPath?.item == 0 {
                addNewContentBO.isHidden = true
                // contentTextField有更動時叫出黑色數字鍵盤
                contentTextField.keyboardType = .numberPad
                contentTextField.keyboardAppearance = .dark
                return
            } else {
                // picker delegate & datasource
                addNewContentBO.isHidden = false
                // 種類、帳戶需要picker，故執行picker功能
                contentPicker.delegate = self
                contentPicker.dataSource = self
                contentTextField.inputView = contentPicker
                contentTextField.keyboardAppearance = .dark
            }
        }
    }
    var getId: String = ""

    @IBOutlet weak var chooseImage: UIImageView!
    @IBOutlet weak var contentTextField: UITextField! {
        didSet {
            contentTextField.delegate = self
        }
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addNewContentBO: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        getId = KeychainWrapper.standard.string(forKey: "id") ?? ""
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    // name: 金額、種類、帳戶, content: 種類內容 - 生成tableview時覆用
    func fillInContent(name: String) {
        titleLabel.text = name
    }

// MARK: - picker
    func contentConfig(segment: Int) {
        controller = UIAlertController(title: "新增選項", message: "", preferredStyle: .alert)
        controller.addTextField { textField in
            textField.placeholder = "內容"
            textField.keyboardType = UIKeyboardType.default
        }
        // 按下OK執行的動作
        let okAction = UIAlertAction(title: "OK", style: .default) { [unowned controller] _ in
            self.content.append(controller.textFields?[0].text ?? "")
            // 按下ok之後同步reload picker的component
            self.contentPicker.reloadAllComponents()
            // 用delegate把已經append的content傳回VC並改值
            self.delegate?.setContent(content: self.content)

// MARK: - 以下待測試 .arrayUnion 方法
            // 按下ok之後判斷現在在哪一頁，然後判斷是哪一個indexPath，把對應的選項上傳到對應的title document裡
            switch self.segmentTag {
            case 0:
                switch self.indexPath?.item {
                case 1:
                    self.createCategory(id: self.getId, subCollection: "expenditure_category")
                case 2:
                    self.createCategory(id: self.getId, subCollection: "account_category")
                default:
                    return
                }
            case 1:
                switch self.indexPath?.item {
                case 1:
                    self.createCategory(id: self.getId, subCollection: "revenue_category")
                case 2:
                    self.createCategory(id: self.getId, subCollection: "account_category")
                default:
                    return
                }
            default:
                self.createCategory(id: self.getId, subCollection: "account_category")
            }
        }

        controller.addAction(okAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        controller.addAction(cancelAction)

        addNewContentBO.addTarget(self, action: #selector(didSelectAddButton), for: .touchUpInside)
    }

    @objc func didSelectAddButton() {
        // 按下add button後把最新選項用delegate傳給VC
        self.delegate?.addNewContent(self)
    }

    // 新增對應category細項
    func createCategory(id: String, subCollection: String) {
        let db = Firestore.firestore()
        let fetchDocumentID = db.collection("user").document(id).collection(subCollection).document()
        let collection = Category(id: fetchDocumentID.documentID, title: controller.textFields?[0].text ?? "")

        do {
            try fetchDocumentID.setData(from: collection)
            print("success create document. ID: \(fetchDocumentID.documentID)")
        } catch {
            print(error)
        }
    }
}

// MARK: - picker
extension AddNewDataTableViewCell: UIPickerViewDelegate, UIPickerViewDataSource {
    // 有幾列可以選擇
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        switch indexPath?.item {
        case 1:
            return 2
        default:
            return 1
        }
    }

    // 每列有多少行資料
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch indexPath?.item {
        case 1:
            if component == 1 {
                return content.count
            }
            return imageArr.count
        case 2:
            return content.count
        default:
            return 0
        }
    }

    // pickerView顯示圖片+文字 兩個種類 - 每個選項顯示的資料, Inherited from UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        switch indexPath?.item {
        case 1:
            if component == 1 {
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 100))
                label.lineBreakMode = .byWordWrapping
                label.numberOfLines = 1
                label.text = content[row]
                label.sizeToFit()
                return label
            }
            return UIImageView(image: imageArr[row])
        case 2:
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 100))
            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = 1
            label.text = content[row]
            label.sizeToFit()
            return label
        default:
            return UIView()
        }
    }

    // pickerView改變選擇後執行的動作, Inherited from UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch indexPath?.item {
        case 1:
            if component == 1 {
                contentTextField.text = content[row]
            } else {
                chooseImage.image = imageArr[row]
                let imageToString = imageArr[row]?.toPngString() ?? ""
                // 把種類對應圖案傳給homeVC
                self.delegate?.getImageName(indexPath: self.indexPath ?? [0, 0], imageName: imageToString)
            }
        case 2:
            contentTextField.text = content[row]
        default:
            return
        }
    }
}

// textField delegate
extension AddNewDataTableViewCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.delegate?.getInputTextField(indexPath: self.indexPath ?? [0, 0], textField: textField.text ?? "")

        self.delegate?.getTitle(indexPath: self.indexPath ?? [0, 0], title: self.titleLabel.text ?? "")
    }
}
