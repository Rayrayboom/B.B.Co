//
//  ViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/28.
//

import UIKit
import FirebaseFirestore
import SwiftKeychainWrapper
import SideMenu

protocol ViewControllerDelegate: AnyObject {
    func getDate(currentDate: String)
}

class ViewController: UIViewController {
    weak var delegate: ViewControllerDelegate?
    var menu: SideMenuNavigationController?
    // 用來存所選日期的data
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
    // 因為UIDatePicker一定要在main thread做，但group是在global執行，因此先在全域宣告一個Date型別的變數，當fetch data抓date picker的日期資料時，改用全域變數的date拿到date的資料(self.date)
    var date = Date()
    let group = DispatchGroup()
// MARK: - 注意！
    var month: String = ""
    var getId: String = ""
    // 生成refreshControl實例
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
        // 生成side menu，實例化class MenuListTableViewController
        menu = SideMenuNavigationController(rootViewController: MenuListTableViewController())
        menu?.leftSide = true
        menu?.setNavigationBarHidden(true, animated: false)
        SideMenuManager.default.leftMenuNavigationController = menu
        SideMenuManager.default.addPanGestureToPresent(toView: self.view)

        showDetailTableView.delegate = self
        showDetailTableView.dataSource = self
        tappedDatePicker()
        // 讓date button一開始顯示當天日期
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy/MM/dd"
        dateBO.setTitle(BBCDateFormatter.shareFormatter.string(from: datePicker.date), for: .normal)
        // 讓UserDefaults一起畫面就先拿到當天的日期資訊，addNewData時才會一開始就顯示當天(而非偵測到點選後才拿到變動的值)
        UserDefaults.standard.set(self.datePicker.date, forKey: "currentDate")
        // 加上refreshControl下拉更新(重fetch data)
        refreshDetail()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        BBCoLoading.loading(view: self.view)
        // 一開啟app先去抓取firebase資料，把現有local端資訊更新為最新
        self.fetchAllData()
    }

    func setupUI() {
        showDetailTableView.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        view.backgroundColor = UIColor().hexStringToUIColor(hex: "EBE5D9")
        dateBO.setTitleColor(UIColor().hexStringToUIColor(hex: "f2f6f7"), for: .normal)
    }
    
    // 當日尚無資料者顯示“目前還沒有記帳喔”
    func checkDataCount() {
        if self.data.isEmpty {
            self.remindLabel.isHidden = false
        } else {
            self.remindLabel.isHidden = true
        }
    }

    // 加上refreshControl下拉更新(重fetch data)
    func refreshDetail() {
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        showDetailTableView.addSubview(refreshControl)
    }

    // refreshControl func
    @objc func refresh(sender: UIRefreshControl) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchAllData()
            self.refreshControl.endRefreshing()
        }
    }

    // 點選date picker時偵測點選的狀態
    func tappedDatePicker() {
        datePicker.tintColor = .systemBrown
        datePicker.addTarget(self, action: #selector(didSelectDate(_:)), for: .valueChanged)
    }

    // 把選擇的date picker日期轉成string給button顯示
    @objc func didSelectDate(_ sender: UIDatePicker) {
        self.date = sender.date
        // 使用UserDefaults方式：先把homeVC的當前點選date存在UserDefaults，當跳到addNewDataVC時再把date拿過來用
        UserDefaults.standard.set(self.date, forKey: "currentDate")
        // 點選date picker時顯示的格式用"yyyy/MM/dd"
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy/MM/dd"
        dateBO.tintColor = .black
        dateBO.setTitle(BBCDateFormatter.shareFormatter.string(from: sender.date), for: .normal)

        self.fetchAllData()
    }

    // 點選date button後date picker和button title會回到今天日期
    @objc func tappedDateButton(_ sender: UIDatePicker) {
        // 點選date button時顯示的格式用"yyyy/MM/dd"
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy/MM/dd"
        // 把date picker日期改為今天
        let today = Date(timeIntervalSinceNow: 0)
        // 按下date button之後要把當天date的值(let today)給外部變數的date，因為在fetch指定日期data時是抓date的日期
        date = today
        // 讓UserDefaults在按下上方button時拿到當天日期資訊，addNewData時才會一開始就顯示當天時間(而非偵測到點選後才拿到變動的值)
        UserDefaults.standard.set(self.date, forKey: "currentDate")
        // 按下date button之後要把date picker顯示的顏色區塊改為當天
        datePicker.setDate(today, animated: true)
        // date button顯示date picker拿到的日期(也就是today的日期)
        dateBO.setTitle(BBCDateFormatter.shareFormatter.string(from: datePicker.date), for: .normal)
        // 點擊date button後會回到當天日期，需要再fetch一次data讓他呈現當天的資料
        self.fetchAllData()
    }

    // 抓指定日期所有subCollection data
    func fetchAllData() {
        // 點選新的日期時，先把存資料、種類的array清空，讓新fetch data塞最新資料，才不會一直append下去
        data = []
        category = []
        let subCollection = ["expenditure", "revenue", "account"]
        
        for num in subCollection {
            group.enter()
            BBCoFireBaseManager.shared.fetchUserSpecific(id: getId, subCollection: num, date: self.date) { [weak self] result in
                guard let self = self else { return }
                self.data = result
                self.group.leave()
            }
        }
        // notify放這邊是因為要等所有API執行完後再執行button點選觸發的功能
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
        // 把homeVC自己傳給editVC
        presentEditVC.homeVC = self
        // 點擊哪個row就把data array對應row的資料傳給editVC
        presentEditVC.data = data[indexPath.row]
        presentEditVC.category = category
        // 依據資料種類跳轉到對應segment control + UI color
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

    // 長按tableView cell叫出刪除、編輯功能
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
                // 點擊哪個row就把data array對應row的資料傳給editVC
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

    // tableView左滑刪除
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            // 順序問題，需要先偵測對應indexPath資料再進行刪除
            BBCoFireBaseManager.shared.deleteSpecificData(id: self.getId, subCollection: "expenditure", dataId: self.data[indexPath.row].id)
            BBCoFireBaseManager.shared.deleteSpecificData(id: self.getId, subCollection: "revenue", dataId: self.data[indexPath.row].id)
            BBCoFireBaseManager.shared.deleteSpecificData(id: self.getId, subCollection: "account", dataId: self.data[indexPath.row].id)
            data.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }
}
