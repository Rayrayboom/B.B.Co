//
//  PieChartViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/6.
//

import UIKit
import Charts
import SwiftKeychainWrapper

class PieChartViewController: UIViewController {
    var pieChartView: PieChartView!
    var fillInPieChartView: UIView!
    // 圓餅圖資料陣列
    var pieChartDataEntries: [PieChartDataEntry] = []
    // 只要有fetch data，data值就會改變，就會執行以下(tableView重新更新畫面 + 重畫pie chart)
    var data: [Account] = [] {
        didSet {
            setupPieChartView()
            pieTableViewConstrains()
            pieTableView.reloadData()
        }
    }

//    var total: [String : Int] = [:]
//    var totalData: [Account] = []

    var getId: String = ""

    // 當segmentTag改值時，讓對應segment的內容重新載入(重畫pie chart)
    var segmentTag: Int? {
        didSet {
            if segmentTag == 0 {
                fetchOverview(id: getId, subCollection: "expenditure")
            } else {
                fetchOverview(id: getId, subCollection: "revenue")
            }
        }
    }
    // 生成refreshControl實例
    var refreshControl = UIRefreshControl()
    let group = DispatchGroup()

// MARK: - 待處理month pie chart
    @IBAction func goToLastMonth(_ sender: UIButton) {
        print("in the last")
//        monthDatePicker.date = DateComponents(calendar: Calendar.current, timeZone: TimeZone.current, year: 2021, month: 11, day: 1).date!
//        print(monthDatePicker.date)
//        let dateComponent = Calendar.current.dateComponents(in: TimeZone.current, from: monthDatePicker.date)
//        var month = dateComponent.month ?? 0
//        month -= 1
        var components = monthDatePicker.calendar.dateComponents([.day, .month, .year], from: monthDatePicker.date)
        let day = components.day
        let month = components.month
        let year = components.year

//        print(monthDatePicker)
//        let today =
//        print(today)
//        monthDatePicker.setDate(today, animated: true)
//        print(monthDatePicker)
    }
    @IBAction func goToNextMonth(_ sender: UIButton) {
        print("in the next")
    }

    @IBOutlet weak var pieTableView: UITableView!
    @IBOutlet weak var sourceSegmentControl: UISegmentedControl!
    @IBOutlet weak var monthDatePicker: UIDatePicker!
    @IBOutlet weak var remindLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        getId = KeychainWrapper.standard.string(forKey: "id") ?? ""
        monthDatePicker.center = view.center
        pieTableView.delegate = self
        pieTableView.dataSource = self
        // 選取segment control時偵測改值狀態
        didSelectSegmentControl()
        setupUI()
        // 畫出view放pieChartView
        setupfillInPieChartView()
        // 加上refreshControl下拉更新(重fetch data)
        refreshPieDetail()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        BBCoLoading.loading(view: self.view)
        // 偵測monthDatePicker改值時觸發func didMonthChanged
        monthDatePicker.addTarget(self, action: #selector(didMonthChanged), for: .valueChanged)
        // 一進頁面後預設顯示支出總覽(default)，每fetch一次資料data就會改動，在data didSet就會重新去畫pie chart
        switch segmentTag {
        case 1:
            fetchOverview(id: getId, subCollection: "revenue")
        default:
            fetchOverview(id: getId, subCollection: "expenditure")
        }
        pieTableView.reloadData()
    }

    // 當monthDatePicker改值時，讓對應segment的內容重新載入(重畫pie chart)，只要重新fetch一次資料即可，因為每fetch一次data就會更新，data didSet就會執行重新畫pie chart的動作
    @objc func didMonthChanged() {
        if segmentTag == 1 {
            fetchOverview(id: getId, subCollection: "revenue")
        } else {
            fetchOverview(id: getId, subCollection: "expenditure")
        }
        BBCoLoading.loading(view: self.view)
    }

    // 加上refreshControl下拉更新(重fetch data)
    func refreshPieDetail() {
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        pieTableView.addSubview(refreshControl)
    }

    // refreshControl func
    @objc func refresh(sender: UIRefreshControl) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.segmentTag == 0 {
                self.fetchOverview(id: self.getId, subCollection: "expenditure")
            } else {
                self.fetchOverview(id: self.getId, subCollection: "revenue")
            }
            self.refreshControl.endRefreshing()
        }
    }

    func setupUI() {
        // segmented control邊框
        sourceSegmentControl.layer.borderWidth = 1.5
        sourceSegmentControl.layer.borderColor = CGColor(red: 233/255, green: 229/255, blue: 218/255, alpha: 1)
        // 預設一進去segmented所選文字為黑色+黃底
        if sourceSegmentControl.selectedSegmentIndex == 0 {
            sourceSegmentControl.selectedSegmentTintColor = UIColor().hexStringToUIColor(hex: "E5BB4B")
            let segementTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            sourceSegmentControl.setTitleTextAttributes(segementTextAttributes, for: .normal)
        }
        monthDatePicker.tintColor = .systemBrown
        pieTableView.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        view.backgroundColor = UIColor().hexStringToUIColor(hex: "EBE5D9")
    }
    
    // 當日尚無資料者顯示“目前還沒有記帳喔”
    func checkDataCount() {
        if self.data.isEmpty {
            self.remindLabel.isHidden = false
        } else {
            self.remindLabel.isHidden = true
        }
    }

    // segmentControl
    func didSelectSegmentControl() {
        // segmentControl 偵測改值狀態
        sourceSegmentControl.addTarget(self, action: #selector(handleSegmentControl), for: .valueChanged)
    }

    // segmentControl - @objc
    @objc func handleSegmentControl() {
        BBCoLoading.loading(view: self.view)
        // 設置segmented control被選取時文字、button顏色
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        sourceSegmentControl.setTitleTextAttributes(titleTextAttributes, for: .selected)

        // 設置對應segmentTag顏色
        segmentTag = sourceSegmentControl.selectedSegmentIndex
        switch segmentTag {
        case 1:
            sourceSegmentControl.selectedSegmentTintColor = UIColor().hexStringToUIColor(hex: "92c7bd")
        default:
            sourceSegmentControl.selectedSegmentTintColor = UIColor().hexStringToUIColor(hex: "E5BB4B")
            sourceSegmentControl.setTitleTextAttributes(titleTextAttributes, for: .selected)
        }
        pieTableView.reloadData()
    }

// MARK: - delete功能先拿掉，因為目前重複資料會加在一起，刪除的話無法一次刪兩筆，待確認是否留

// MARK: - Pie Chart
    // 建立圓餅圖view（生成物件、位置、內容）
    func setupPieChartView() {
        pieChartDataEntries = []
        // 當segment選取改變時，把fillInPieChartView上的subvivew全部清掉（含pieChartView）
        let subviews = fillInPieChartView.subviews
        for subview in subviews {
            subview.removeFromSuperview()
        }
        // 生成PieChartView物件
        pieChartView = PieChartView()
        // pieChartView constraint
        self.fillInPieChartView.addSubview(pieChartView)
        pieChartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pieChartView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 130),
            pieChartView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            pieChartView.widthAnchor.constraint(equalToConstant: self.view.bounds.width - 40),
            pieChartView.heightAnchor.constraint(equalToConstant: self.view.bounds.height / 3)
        ])
        // 圓餅圖內容
        pieChartViewDataInput()
        // 圓餅圖規格
        pieChartViewConfig()
    }

    // 計算帳目細項種類、金額，傳入data return [String : Int]
    func pieChartData(pieData: [Account]) -> [String : Int] {
        var total: [String : Int] = [:]
        for num in pieData {
            guard let category = num.category else { fatalError() }
            if total[category] == nil {
                total[num.category ?? ""] = Int(num.amount)
            } else {
                guard var amount = total[category] else { fatalError() }
                amount += Int(num.amount) ?? 0
                total[category] = amount
            }
        }
        return total
    }

    // 圓餅圖內容
    func pieChartViewDataInput() {
        // 計算後的pie chart data
        let total = pieChartData(pieData: data)
        // 把要給pie chart的值append進array
        for num in total.keys {
            pieChartDataEntries.append(PieChartDataEntry.init(value: Double(total[num] ?? 0), label: num, icon: nil))
        }
    }

    // 圓餅圖規格
    func pieChartViewConfig() {
        let chartDataSet = PieChartDataSet(entries: pieChartDataEntries, label: "")
        // 設定圓餅圖的顏色
        chartDataSet.colors = [UIColor().hexStringToUIColor(hex: "de9493"),
                               UIColor().hexStringToUIColor(hex: "f0b77b"),
                               UIColor().hexStringToUIColor(hex: "b0bdd0"),
                               UIColor().hexStringToUIColor(hex: "59b9bb"),
                               UIColor().hexStringToUIColor(hex: "2580cb"),
                               UIColor().hexStringToUIColor(hex: "c93640"),
                               UIColor().hexStringToUIColor(hex: "f6cb61"),
                               UIColor().hexStringToUIColor(hex: "b2c251"),
                               UIColor().hexStringToUIColor(hex: "57549e"),
                               UIColor().hexStringToUIColor(hex: "284155")]
        // 設定資料數值的字體大小
        chartDataSet.valueTextColor = .black
        chartDataSet.valueFont = UIFont.systemFont(ofSize: 15.0)

        let chartData = PieChartData(dataSets: [chartDataSet])
        pieChartView.legend.enabled = false
        // 將 chartData 指派給 pieChartView
        pieChartView.data = chartData
        // 設定下方圖例樣式，default為圓形
        pieChartView.legend.form = .default
        // 是否能單點選取
        pieChartView.highlightPerTapEnabled = true
        // 按下對應扇形後，凸出來的多寡
        chartDataSet.selectionShift = 5
        // 扇形間隔
        chartDataSet.sliceSpace = 3
        // 設置為實心圓
        pieChartView.drawHoleEnabled = false

        // 設定數值包含$符號
        let formatter = NumberFormatter()
        formatter.positivePrefix = "$"
        chartData.setValueFormatter(DefaultValueFormatter(formatter: formatter))
    }

    // 設定pieTableView constrains
    func pieTableViewConstrains() {
        pieTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pieTableView.topAnchor.constraint(equalTo: pieChartView.bottomAnchor, constant: 0),
            pieTableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            pieTableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            pieTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }

    // 設定fillInPieChartView constrains, 拿來放pieChartView
    func setupfillInPieChartView() {
        fillInPieChartView = UIView()
        self.view.addSubview(fillInPieChartView)
        fillInPieChartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fillInPieChartView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 120),
            fillInPieChartView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            fillInPieChartView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            fillInPieChartView.heightAnchor.constraint(equalToConstant: self.view.bounds.height / 3)
        ])
    }

    // (月份總覽)當資料為等於選取monthDatePicker的月份時，抓取所有subCollection該月份的資料
    func fetchOverview(id: String, subCollection: String) {
        data = []
        group.enter()
        BBCoFireBaseManager.shared.fetchMonthOverview(id: id, subCollection: subCollection, monthData: monthDatePicker.date) { result in
            self.data = result
            print("=== data from result", self.data)
            self.group.leave()
        }
        // notify放這邊是因為要等所有API執行完後再執行button點選觸發的功能
        group.notify(queue: .main) {
            self.checkDataCount()
            print("=== in notify")
        }
    }
}

extension PieChartViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    // 長按tableView cell叫出刪除功能
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions -> UIMenu? in
            let deleteAction = UIAction(title: "刪除", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: .off) { action in
                switch self.segmentTag {
                case 1:
                    BBCoFireBaseManager.shared.deleteSpecificData(id: self.getId, subCollection: "revenue", dataId: self.data[indexPath.row].id)
                    self.fetchOverview(id: self.getId, subCollection: "revenue")
                default:
                    BBCoFireBaseManager.shared.deleteSpecificData(id: self.getId, subCollection: "expenditure", dataId: self.data[indexPath.row].id)
                    self.fetchOverview(id: self.getId, subCollection: "expenditure")
                }
            }
            return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: [deleteAction])
        }
    }
}

extension PieChartViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        for num in total.keys {
//            totalData.append(Account.init(id: "autoId", amount: String(total[num] ?? 0), category: num, date: "autoDate", month: "autoMonth"))
//        }
//        return totalData.count
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let pieCell = tableView.dequeueReusableCell(withIdentifier: "pieCell") as? PieChartTableViewCell else {
            fatalError("can not create cell")
        }
        pieCell.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")

        pieCell.categoryImage.image = data[indexPath.row].categoryImage?.toImage()
//        pieCell.nameLabel.text = totalData[indexPath.row].category
//        pieCell.amountLabel.text = totalData[indexPath.row].amount
        pieCell.nameLabel.text = data[indexPath.row].category
        pieCell.amountLabel.text = "$ \(data[indexPath.row].amount)"

        return pieCell
    }

// MARK: - delete功能先拿掉，因為目前重複資料會加在一起，刪除的話無法一次刪兩筆，待確認是否留
//     tableView左滑刪除 & 連動firebase
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            // 依據目前在哪個segment control刪除對應種類firebase資料，和下面的data.remove是順序問題，需要先偵測對應indexPath資料再進行刪除
            switch segmentTag {
            case 1:
                BBCoFireBaseManager.shared.deleteSpecificData(id: self.getId, subCollection: "revenue", dataId: self.data[indexPath.row].id)
            default:
                BBCoFireBaseManager.shared.deleteSpecificData(id: self.getId, subCollection: "expenditure", dataId: self.data[indexPath.row].id)
            }
            data.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.checkDataCount()
            tableView.endUpdates()
        }
    }
}
