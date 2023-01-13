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

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            categoryListViewModel.deleteSideMenuCategory(detailRow: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }
}
