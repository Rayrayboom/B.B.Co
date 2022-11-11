//
//  PieChartViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/6.
//

import UIKit
import Charts
import FirebaseFirestore

class PieChartViewController: UIViewController {
    var pieChartView: PieChartView!
    var fillInPieChartView: UIView!
    // 圓餅圖資料陣列
    var pieChartDataEntries: [PieChartDataEntry] = []
    // 等fetch data回來有值後，讓tableView重新更新畫面
    var data: [Account] = [] {
        didSet {
            pieTableView.reloadData()
            setupPieChartView()
            pieTableViewConstrains()
        }
    }

    // 當segmentTag改值時，讓對應segment的內容重新載入(重畫pie chart)
    var segmentTag: Int? {
        didSet {
            if segmentTag == 0 {
                recreateExpenditurePieChart()
            } else {
                recreateRevenuePieChart()
            }
        }
    }

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

    override func viewDidLoad() {
        super.viewDidLoad()
        monthDatePicker.center = view.center
        // 一進頁面預設顯示支出總覽
        fetchUser(subCollection: "expenditure")
        pieTableView.delegate = self
        pieTableView.dataSource = self
        // 選取segment control時拿SegmentIndex
        didSelectSegmentControl()
        // 畫出view放pieChartView
        setupfillInPieChartView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        // 偵測monthDatePicker改值時觸發func didMonthChanged
        monthDatePicker.addTarget(self, action: #selector(didMonthChanged), for: .valueChanged)
        pieTableView.reloadData()
    }

    // 重新畫pie chart based on expenditure data
    func recreateExpenditurePieChart() {
        data = []
        pieChartDataEntries = []
        // 當segment選取改變時，把fillInPieChartView上的subvivew全部清掉（含pieChartView）
        let subviews = fillInPieChartView.subviews
        for subview in subviews {
            subview.removeFromSuperview()
        }
        // 接著重新抓取支出總覽資料
        fetchUser(subCollection: "expenditure")
        // 並再次生成fillInPieChartView & pieChartView
        setupPieChartView()
    }

    // 重新畫pie chart based on revenue data
    func recreateRevenuePieChart() {
        data = []
        pieChartDataEntries = []
        // 當segment選取改變時，把fillInPieChartView上的subvivew全部清掉（含pieChartView）
        let subviews = fillInPieChartView.subviews
        for subview in subviews {
            subview.removeFromSuperview()
        }
        // 接著重新抓取支出總覽資料
        fetchUser(subCollection: "revenue")
        // 並再次生成fillInPieChartView & pieChartView
        setupPieChartView()
    }

    // 當monthDatePicker改值時，讓對應segment的內容重新載入(重畫pie chart)
    @objc func didMonthChanged() {
        if segmentTag == 0 {
            recreateExpenditurePieChart()
        } else {
            recreateRevenuePieChart()
        }
    }

    func didSelectSegmentControl() {
        // segmentControl 偵測改值狀態
        sourceSegmentControl.addTarget(self, action: #selector(handelSegmentControl), for: .valueChanged)
    }

    @objc func handelSegmentControl() {
        segmentTag = sourceSegmentControl.selectedSegmentIndex
        print("This is current segmentTag \(segmentTag)")
        pieTableView.reloadData()
    }

    // 建立圓餅圖view（生成物件、位置、內容）
    func setupPieChartView() {
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

    // 圓餅圖內容
    func pieChartViewDataInput() {
        var total: [String: Double] = [:]
        for num in data {
            guard let category = num.category else { return }
            if total[category] == nil {
                total[num.category ?? ""] = Double(num.amount)
            } else {
                guard var amount = total[category] else { return }
                amount += Double(num.amount)
                ?? 0
                total[category] = amount
            }
        }

        for num in total.keys {
            pieChartDataEntries.append(PieChartDataEntry.init(value: total[num] ?? 0, label: num, icon: nil))
        }
    }

    // 圓餅圖規格
    func pieChartViewConfig() {
        let chartDataSet = PieChartDataSet(entries: pieChartDataEntries, label: "")
        // 設定圓餅圖的顏色
        chartDataSet.colors = ChartColorTemplates.vordiplom()
        // 設定資料數值的字體大小
        chartDataSet.valueTextColor = .black
        chartDataSet.valueFont = UIFont.systemFont(ofSize: 15.0)

        let chartData = PieChartData(dataSets: [chartDataSet])
//        let chartData = PieChartData(dataSets: [chartDataSet])
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
    func fetchUser(subCollection: String) {
        // fetch firebase指定條件為date的資料時，用"yyyy 年 MM 月"格式來偵測
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月"
        let dataBase = Firestore.firestore()
        print("this is month \(BBCDateFormatter.shareFormatter.string(from: monthDatePicker.date))")
        // 抓取哪個月份由monthDatePicker.date決定
        dataBase.collection("user/vy4oSHvNXfzBAKzwj95x/\(subCollection)")
            .whereField("month", isEqualTo: BBCDateFormatter.shareFormatter.string(from: monthDatePicker.date))
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let account = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Account.self)
                }
                self.data.append(contentsOf: account)
                print("data here \(self.data)")
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
}

extension PieChartViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let pieCell = tableView.dequeueReusableCell(withIdentifier: "pieCell") as? PieChartTableViewCell else {
            fatalError("can not create cell")
        }

        pieCell.categoryImage.image = UIImage(systemName: "hand.thumbsup.fill")
        pieCell.nameLabel.text = data[indexPath.row].category
        pieCell.amountLabel.text = data[indexPath.row].amount

        return pieCell
    }
}
