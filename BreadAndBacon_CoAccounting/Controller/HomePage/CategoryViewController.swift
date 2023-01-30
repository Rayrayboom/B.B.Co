//
//  CategoryViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/18.
//

import UIKit
import SwiftKeychainWrapper

final class CategoryViewController: UIViewController {
    // var viewModel 是為了可以更改 viewModel 裡的 indexPathRow (因為viewModel是用struct去宣告(immutable); 如果是class就可以用let)
    var categoryListViewModel = CategoryListViewModel()
    var category: [Category] = [] {
        didSet {
            categoryTableView.reloadData()
        }
    }
    var controller = UIAlertController()

    @IBOutlet weak var categoryTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        tapDismiss()
        categoryListViewModel.fetchSideMenuCategory()
        categoryListViewModel.category.bind { [unowned self] result in
            self.category = result
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
}

extension CategoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions -> UIMenu? in
            let deleteAction = UIAction(title: "刪除", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: .off) { [unowned self] action in
                self.categoryListViewModel.deleteSideMenuCategory(detailRow: indexPath.row)
            }
            let editAction = UIAction(title: "編輯", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: .off) { [unowned self] action in
                controller = UIAlertController(title: "編輯種類", message: nil, preferredStyle: .alert)
                controller.addTextField { textField in
                    textField.text = category[indexPath.row].title
                    textField.keyboardType = UIKeyboardType.default
                    textField.keyboardAppearance = .dark
                }
                let okAction = UIAlertAction(title: "修改", style: .default) { [unowned self] action in
                    categoryListViewModel.editSideMenuCategory(detailRow: indexPath.row, textFieldContent: controller.textFields?[0].text ?? "")
                    categoryListViewModel.fetchSideMenuCategory()
                    categoryListViewModel.category.bind { [unowned self] result in
                        self.category = result
                    }
                }
                controller.addAction(okAction)
                let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
                controller.addAction(cancelAction)
                present(controller, animated: true)
            }
            return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: [deleteAction, editAction])
        }
    }
}

extension CategoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return HeaderTitle.categoryList
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return category.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let categoryCell = tableView.dequeueReusableCell(withIdentifier: Identifier.categoryCellID) as? CategoryTableViewCell
        else {
            fatalError(ErrorMessage.fatalErrorMSG)
        }
        categoryCell.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        categoryCell.categoryLabel.text = category[indexPath.row].title
        return categoryCell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            categoryListViewModel.deleteSideMenuCategory(detailRow: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.reloadData()
            tableView.endUpdates()
        }
    }
}
