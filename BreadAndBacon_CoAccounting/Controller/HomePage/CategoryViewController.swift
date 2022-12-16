//
//  CategoryViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/18.
//

import UIKit
import FirebaseFirestore
import SwiftKeychainWrapper

class CategoryViewController: UIViewController {
    var category: [Category] = [] {
        didSet {
            categoryTableView.reloadData()
        }
    }
    var indexPathRow: Int = 0
    var getId: String = ""
    let group = DispatchGroup()

    @IBOutlet weak var categoryTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        getId = KeychainWrapper.standard.string(forKey: "id") ?? ""
        setupUI()
        tapDismiss()
        // 判斷點選side menu對應cell時fetch不同category資料
        switch indexPathRow {
        case 0:
            BBCoFireBaseManager.shared.fetchSideMenuCategory(id: getId, subCollection: "expenditure") { [weak self] result in
                guard let self = self else { return }
                self.category = result
            }
        case 1:
            BBCoFireBaseManager.shared.fetchSideMenuCategory(id: getId, subCollection: "revenue") { [weak self] result in
                guard let self = self else { return }
                self.category = result
            }
        case 2:
            BBCoFireBaseManager.shared.fetchSideMenuCategory(id: getId, subCollection: "account") { [weak self] result in
                guard let self = self else { return }
                self.category = result
            }
        default:
            break
        }

        categoryTableView.delegate = self
        categoryTableView.dataSource = self
    }

    func setupUI() {
        categoryTableView.backgroundColor = UIColor().hexStringToUIColor(hex: "EBE5D9")
        view.backgroundColor = UIColor().hexStringToUIColor(hex: "1b4464")
    }

    func tapDismiss() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Cancel"),
            style: .plain,
            target: self,
            action: #selector(dismissCategory))
    }

    @objc func dismissCategory() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    // 用category_id從firebase上刪除資料，delete firebase data需要一層一層找，不能用路徑
    func deleteSpecificData(id: String, subCollection: String, indexPathRow: Int) {
        let dataBase = Firestore.firestore()
        let documentRef = dataBase
            .collection("user")
            .document(id)
            .collection("\(subCollection)_category")
            .document(category[indexPathRow].id ?? "")
        documentRef.delete()
    }
}

extension CategoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension CategoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "種類列表"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return category.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let categoryCell = tableView.dequeueReusableCell(withIdentifier: "categoryCell") as? CategoryTableViewCell
        else {
            fatalError("can not create category Cell")
        }
        categoryCell.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        categoryCell.categoryLabel.text = category[indexPath.row].title
        return categoryCell
    }

    // tableView左滑刪除 & 連動firebase
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            // 刪除firebase資料，和下面的data.remove是順序問題，需要先偵測對應indexPath資料再進行刪除
            switch indexPathRow {
            case 0:
//                BBCoFireBaseManager.shared.deleteSideMenuCategory(id: getId, subCollection: "expenditure", indexPathRow: indexPath.row, dataId: category[indexPathRow].id ?? "")
                deleteSpecificData(id: getId, subCollection: "expenditure", indexPathRow: indexPath.row)
            case 1:
//                BBCoFireBaseManager.shared.deleteSideMenuCategory(id: getId, subCollection: "revenue", indexPathRow: indexPath.row, dataId: category[indexPathRow].id ?? "")
                deleteSpecificData(id: getId, subCollection: "revenue", indexPathRow: indexPath.row)
            case 2:
//                BBCoFireBaseManager.shared.deleteSideMenuCategory(id: getId, subCollection: "account", indexPathRow: indexPath.row, dataId: category[indexPathRow].id ?? "")
                deleteSpecificData(id: getId, subCollection: "account", indexPathRow: indexPath.row)
            default:
                break
            }
            category.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }
}
