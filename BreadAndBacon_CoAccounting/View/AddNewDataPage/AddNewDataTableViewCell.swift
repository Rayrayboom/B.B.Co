//
//  AddNewDataTableViewCell.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/30.
//

import UIKit
import FirebaseFirestore
import SwiftKeychainWrapper
import IQKeyboardManagerSwift

protocol AddNewDataTableViewCellDelegate: AnyObject {
    func addNewContent(_ cell: AddNewDataTableViewCell, indexPathItem: Int)
    func getInputTextField(indexPath: IndexPath, textField: String)
    func getTitle(indexPath: IndexPath, title: String)
    func setContent(indexPathItem: Int, content: [String])
    func getImageName(indexPath: IndexPath, imageName: String)
}

class AddNewDataTableViewCell: UITableViewCell {
    weak var delegate: AddNewDataTableViewCellDelegate?
    var content: [String] = []
    var imageArr: [UIImage?] = []
    let contentPicker = UIPickerView()
    var controller = UIAlertController()
    var segmentTag = 0
    var presentCalculateVC: CalculateViewController?
    var amountFromCalculator = ""
    var indexPath: IndexPath? {
        didSet {
            if indexPath?.item == 0 {
                addNewContentBO.isHidden = true
                contentTextField.inputView = UIView.init(frame: CGRect.zero)
                contentTextField.inputAccessoryView = UIView.init(frame: CGRect.zero)
                return
            } else {
                addNewContentBO.isHidden = false
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
        self.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        contentTextField.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        contentTextField.layer.borderWidth = 1
        contentTextField.layer.borderColor = CGColor.init(red: 189/255, green: 189/255, blue: 190/255, alpha: 1)
        contentTextField.layer.cornerRadius = 5
        contentTextField.textAlignment = .center
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentTextField.text = ""
        chooseImage.image = nil
        contentTextField.inputView = nil
    }

    func setContentAndImage(content: [String], image: [UIImage?], indexPath: IndexPath, segmentTag: Int) {
        self.content = content
        self.imageArr = image
        self.indexPath = indexPath
        self.segmentTag = segmentTag
    }

    func fillInContent(name: String) {
        titleLabel.text = name
    }

    func contentConfig(segment: Int, titleName: String) {
        titleLabel.text = titleName
        controller = UIAlertController(title: "新增選項", message: "", preferredStyle: .alert)
        controller.addTextField { textField in
            textField.placeholder = "內容"
            textField.keyboardType = UIKeyboardType.default
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { [unowned controller] _ in
            self.content.append(controller.textFields?[0].text ?? "")
            self.contentPicker.reloadAllComponents()
            self.delegate?.setContent(indexPathItem: self.indexPath?.item ?? 0, content: self.content)

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
        self.delegate?.addNewContent(self, indexPathItem: indexPath?.item ?? 0)
    }

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

extension AddNewDataTableViewCell: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        switch indexPath?.item {
        case 1:
            return 2
        default:
            return 1
        }
    }

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

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 80
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch indexPath?.item {
        case 1:
            if component == 1 {
                contentTextField.text = content[row]
            } else {
                chooseImage.image = imageArr[row]
                let imageToString = imageArr[row]?.toPngString() ?? ""
                self.delegate?.getImageName(indexPath: self.indexPath ?? [0, 0], imageName: imageToString)
            }
        case 2:
            contentTextField.text = content[row]
        default:
            return
        }
    }
}

extension AddNewDataTableViewCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch indexPath?.item {
        case 1:
            if contentTextField.text == "" {
                contentTextField.text = content[0]
                chooseImage.image = imageArr[0]
                self.delegate?.getImageName(indexPath: self.indexPath ?? [0, 0], imageName: imageArr[0]?.toPngString() ?? "")
            } else {
                return
            }
        case 2:
            if contentTextField.text == "" {
                contentTextField.text = content[0]
            } else {
                return
            }
        default:
            let addNewDataStoryboard = UIStoryboard(name: "AddNewData", bundle: nil)
            presentCalculateVC = addNewDataStoryboard.instantiateViewController(withIdentifier: "calculateVC") as? CalculateViewController
            presentCalculateVC?.modalPresentationStyle = .overCurrentContext
            self.delegate?.addNewContent(self, indexPathItem: indexPath?.item ?? 0)

            presentCalculateVC?.closure = {[weak self] text in
                if self?.contentTextField.text == "" {
                    self?.contentTextField.text = text
                    self?.amountFromCalculator = text
                    self?.delegate?.getInputTextField(indexPath: self?.indexPath ?? [0, 0], textField: textField.text ?? "")
                } else {
                    self?.contentTextField.text = text
                    self?.delegate?.getInputTextField(indexPath: self?.indexPath ?? [0, 0], textField: textField.text ?? "")
                }
            }
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.delegate?.getInputTextField(indexPath: self.indexPath ?? [0, 0], textField: textField.text ?? "")
        self.delegate?.getTitle(indexPath: self.indexPath ?? [0, 0], title: self.titleLabel.text ?? "")
    }
}
