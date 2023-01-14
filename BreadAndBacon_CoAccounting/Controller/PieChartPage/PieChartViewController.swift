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
    var getId: String = ""
    var segmentTag: Int? {
        didSet {
            if segmentTag == 0 {
                fetchOverview(id: getId, subCollection: "expenditure")
            } else {
                fetchOverview(id: getId, subCollection: "revenue")
            }
        }
    }
    var refreshControl = UIRefreshControl()
    let group = DispatchGroup()

    @IBAction func goToLastMonth(_ sender: UIButton) {
        print("in the last")
        var components = monthDatePicker.calendar.dateComponents([.day, .month, .year], from: monthDatePicker.date)
        let day = components.day
        let month = components.month
        let year = components.year
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
        didSelectSegmentControl()
        setupUI()
        setupfillInPieChartView()
        refreshPieDetail()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        BBCoLoading.loading(view: self.view)
        monthDatePicker.addTarget(self, action: #selector(didMonthChanged), for: .valueChanged)
        switch segmentTag {
        case 1:
            fetchOverview(id: getId, subCollection: "revenue")
        default:
            fetchOverview(id: getId, subCollection: "expenditure")
        }
        pieTableView.reloadData()
    }

    @objc func didMonthChanged() {
        if segmentTag == 1 {
            fetchOverview(id: getId, subCollection: "revenue")
        } else {
            fetchOverview(id: getId, subCollection: "expenditure")
        }
        BBCoLoading.loading(view: self.view)
    }

    func refreshPieDetail() {
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        pieTableView.addSubview(refreshControl)
    }

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
        sourceSegmentControl.layer.borderWidth = 1.5
        sourceSegmentControl.layer.borderColor = CGColor(red: 233/255, green: 229/255, blue: 218/255, alpha: 1)
        if sourceSegmentControl.selectedSegmentIndex == 0 {
            sourceSegmentControl.selectedSegmentTintColor = UIColor().hexStringToUIColor(hex: "E5BB4B")
            let segementTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            sourceSegmentControl.setTitleTextAttributes(segementTextAttributes, for: .normal)
        }
        monthDatePicker.tintColor = .systemBrown
        pieTableView.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        view.backgroundColor = UIColor().hexStringToUIColor(hex: "EBE5D9")
    }

    func checkDataCount() {
        if self.data.isEmpty {
            self.remindLabel.isHidden = false
        } else {
            self.remindLabel.isHidden = true
        }
    }

    func didSelectSegmentControl() {
        sourceSegmentControl.addTarget(self, action: #selector(handleSegmentControl), for: .valueChanged)
    }

    @objc func handleSegmentControl() {
        BBCoLoading.loading(view: self.view)
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        sourceSegmentControl.setTitleTextAttributes(titleTextAttributes, for: .selected)
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
        let totalAmount = pieChartViewDataInput(pieData: data)
        // 圓餅圖規格
        pieChartViewConfig(totalAmount: totalAmount)
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
    func pieChartViewDataInput(pieData: [Account]) -> Int {
        // 計算後的pie chart data
        let total = pieChartData(pieData: pieData)
        // 儲存總金額
        var totalAmount = 0

        // 把要給pie chart的值append進array
        for num in total.keys {
            pieChartDataEntries.append(PieChartDataEntry.init(value: Double(total[num] ?? 0), label: num, icon: nil))
            totalAmount += Int(total[num] ?? 0)
        }
        return totalAmount
    }

    // 圓餅圖規格
    func pieChartViewConfig(totalAmount: Int) {
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
//        chartDataSet.label = nil
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
        // 不顯示數值
//        chartDataSet.drawValuesEnabled = false
        // 設置為空心圓
        pieChartView.drawHoleEnabled = true
        // 設置中央金額總和
        pieChartView.centerText = "總金額\n\(totalAmount)"
        pieChartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)

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

    func fetchOverview(id: String, subCollection: String) {
        data = []
        group.enter()
        BBCoFireBaseManager.shared.fetchMonthOverview(id: id, subCollection: subCollection, monthData: monthDatePicker.date) { result in
            self.data = result
            print("=== data from result", self.data)
            self.group.leave()
        }
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
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let pieCell = tableView.dequeueReusableCell(withIdentifier: "pieCell") as? PieChartTableViewCell else {
            fatalError("can not create cell")
        }
        pieCell.backgroundColor = UIColor().hexStringToUIColor(hex: "f2f6f7")
        pieCell.categoryImage.image = data[indexPath.row].categoryImage?.toImage()
        pieCell.nameLabel.text = data[indexPath.row].category
        pieCell.amountLabel.text = "$ \(data[indexPath.row].amount)"
        return pieCell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
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
