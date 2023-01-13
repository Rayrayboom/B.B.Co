//
//  ViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/28.
//

import UIKit
import SwiftKeychainWrapper
import SideMenu

protocol ViewControllerDelegate: AnyObject {
    func getDate(currentDate: String)
}

class ViewController: UIViewController {
    weak var delegate: ViewControllerDelegate?
    var menu: SideMenuNavigationController?
    var data: [Account] = [] {
        didSet {
            self.showDetailTableView.reloadData()
        }
    }
    var category: [Category] = [] {
        didSet {
            self.showDetailTableView.reloadData()
        }
    }
    var date = Date()
    let group = DispatchGroup()
    var month: String = ""
    var getId: String = ""
    var refreshControl = UIRefreshControl()

    @IBOutlet weak var remindLabel: UILabel!
    @IBOutlet weak var dateBO: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var showDetailTableView: UITableView!
    @IBAction func didTapMenu() {
        guard let menu = menu else { fatalError("can not present side menu") }
        present(menu, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        getId = KeychainWrapper.standard.string(forKey: "id") ?? ""
        menu = SideMenuNavigationController(rootViewController: MenuListTableViewController())
        menu?.leftSide = true
        menu?.setNavigationBarHidden(true, animated: false)
        SideMenuManager.default.leftMenuNavigationController = menu
        SideMenuManager.default.addPanGestureToPresent(toView: self.view)

        showDetailTableView.delegate = self
        showDetailTableView.dataSource = self
        tappedDatePicker()
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy/MM/dd"
        dateBO.setTitle(BBCDateFormatter.shareFormatter.string(from: datePicker.date), for: .normal)
        UserDefaults.standard.set(self.datePicker.date, forKey: "currentDate")
        refreshDetail()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        BBCoLoading.loading(view: self.view)
        self.fetchAllData()
    }

    func setupUI() {
        showDetailTableView.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        view.backgroundColor = UIColor().hexStringToUIColor(hex: "EBE5D9")
        dateBO.setTitleColor(UIColor().hexStringToUIColor(hex: "f2f6f7"), for: .normal)
    }

    func checkDataCount() {
        if self.data.isEmpty {
            self.remindLabel.isHidden = false
        } else {
            self.remindLabel.isHidden = true
        }
    }

    func refreshDetail() {
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        showDetailTableView.addSubview(refreshControl)
    }

    @objc func refresh(sender: UIRefreshControl) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchAllData()
            self.refreshControl.endRefreshing()
        }
    }

    func tappedDatePicker() {
        datePicker.tintColor = .systemBrown
        datePicker.addTarget(self, action: #selector(didSelectDate(_:)), for: .valueChanged)
    }

    @objc func didSelectDate(_ sender: UIDatePicker) {
        self.date = sender.date
        UserDefaults.standard.set(self.date, forKey: "currentDate")
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy/MM/dd"
        dateBO.tintColor = .black
        dateBO.setTitle(BBCDateFormatter.shareFormatter.string(from: sender.date), for: .normal)
        self.fetchAllData()
    }

    @objc func tappedDateButton(_ sender: UIDatePicker) {
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy/MM/dd"
        let today = Date(timeIntervalSinceNow: 0)
        date = today
        UserDefaults.standard.set(self.date, forKey: "currentDate")
        datePicker.setDate(today, animated: true)
        dateBO.setTitle(BBCDateFormatter.shareFormatter.string(from: datePicker.date), for: .normal)
        self.fetchAllData()
    }

    func fetchAllData() {
        data = []
        category = []
        let subCollection = ["expenditure", "revenue", "account"]
        
        for num in subCollection {
            group.enter()
            BBCoFireBaseManager.shared.fetchUserSpecific(id: getId, subCollection: num, date: self.date) { [weak self] result in
                guard let self = self else { return }
                self.data += result
                self.group.leave()
            }
        }
        group.notify(queue: .main) {
            self.checkDataCount()
            self.dateBO.addTarget(self, action: #selector(self.tappedDateButton), for: .touchUpInside)
            self.showDetailTableView.reloadData()
        }
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let presentEditVC = self.storyboard?.instantiateViewController(withIdentifier: "editVC") as? EditViewController
        else {
            fatalError("can not find editVC")
        }
        presentEditVC.homeVC = self
        presentEditVC.data = data[indexPath.row]
        presentEditVC.category = category
        if data[indexPath.row].segmentTag == 0 {
            presentEditVC.segmentTag = 0
            presentEditVC.sourceSegmentControl.selectedSegmentIndex = 0
            presentEditVC.sourceSegmentControl.selectedSegmentTintColor =
                UIColor().hexStringToUIColor(hex: "E5BB4B")
        } else if data[indexPath.row].segmentTag == 1 {
            presentEditVC.segmentTag = 1
            presentEditVC.sourceSegmentControl.selectedSegmentIndex = 1
            presentEditVC.sourceSegmentControl.selectedSegmentTintColor = UIColor().hexStringToUIColor(hex: "92c7bd")
        } else if data[indexPath.row].segmentTag == 2 {
            presentEditVC.segmentTag = 2
            presentEditVC.sourceSegmentControl.selectedSegmentIndex = 2
            presentEditVC.sourceSegmentControl.selectedSegmentTintColor = .systemBrown
        }

        let navigation = UINavigationController(rootViewController: presentEditVC)
        navigation.modalPresentationStyle = .fullScreen
        present(navigation, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions -> UIMenu? in
            let deleteAction = UIAction(title: "刪除", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: .off) { action in
                BBCoFireBaseManager.shared.deleteSpecificData(id: self.getId, subCollection: "expenditure", dataId: self.data[indexPath.row].id)
                BBCoFireBaseManager.shared.deleteSpecificData(id: self.getId, subCollection: "revenue", dataId: self.data[indexPath.row].id)
                BBCoFireBaseManager.shared.deleteSpecificData(id: self.getId, subCollection: "account", dataId: self.data[indexPath.row].id)
                self.fetchAllData()
            }
            let editAction = UIAction(title: "編輯", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: .off) { action in
                guard let presentEditVC = self.storyboard?.instantiateViewController(withIdentifier: "editVC") as? EditViewController
                else {
                    fatalError("can not find editVC")
                }
                presentEditVC.data = self.data[indexPath.row]
                presentEditVC.category = self.category

                let navigation = UINavigationController(rootViewController: presentEditVC)
                navigation.modalPresentationStyle = .fullScreen
                self.present(navigation, animated: true, completion: nil)
            }
            return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: [deleteAction, editAction])
        }
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let homeDetailCell = tableView.dequeueReusableCell(withIdentifier: "homeDetailCell") as? HomeDetailTableViewCell else {
            fatalError("can not create cell")
        }
        homeDetailCell.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")

        let image = data[indexPath.row].categoryImage?.toImage()
        homeDetailCell.categoryImage.image = image
        homeDetailCell.nameLabel.text = data[indexPath.row].category
        homeDetailCell.amountLabel.text = "$ \(data[indexPath.row].amount)"
        switch data[indexPath.row].sourceAccountId {
        case nil:
            homeDetailCell.detailLabel.text = data[indexPath.row].detail
        default:
            homeDetailCell.detailLabel.text = data[indexPath.row].account
        }

        return homeDetailCell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            BBCoFireBaseManager.shared.deleteSpecificData(id: self.getId, subCollection: "expenditure", dataId: self.data[indexPath.row].id)
            BBCoFireBaseManager.shared.deleteSpecificData(id: self.getId, subCollection: "revenue", dataId: self.data[indexPath.row].id)
            BBCoFireBaseManager.shared.deleteSpecificData(id: self.getId, subCollection: "account", dataId: self.data[indexPath.row].id)
            data.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }
}
