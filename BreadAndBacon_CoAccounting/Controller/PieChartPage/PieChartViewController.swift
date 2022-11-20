//
//  PieChartViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/6.
//

import UIKit
import Charts
import FirebaseFirestore
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
                fetchUser(id: getId, subCollection: "expenditure")
            } else {
                fetchUser(id: getId, subCollection: "revenue")
            }
        }
    }
    // 生成refreshControl實例
    var refreshControl = UIRefreshControl()

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
        // 偵測monthDatePicker改值時觸發func didMonthChanged
        monthDatePicker.addTarget(self, action: #selector(didMonthChanged), for: .valueChanged)
        // 一進頁面後預設顯示支出總覽(default)，每fetch一次資料data就會改動，在data didSet就會重新去畫pie chart
        switch segmentTag {
        case 1:
            fetchUser(id: getId, subCollection: "revenue")
        default:
            fetchUser(id: getId, subCollection: "expenditure")
        }
        pieTableView.reloadData()
    }

    // 當monthDatePicker改值時，讓對應segment的內容重新載入(重畫pie chart)，只要重新fetch一次資料即可，因為每fetch一次data就會更新，data didSet就會執行重新畫pie chart的動作
    @objc func didMonthChanged() {
        if segmentTag == 1 {
            fetchUser(id: getId, subCollection: "revenue")
        } else {
            fetchUser(id: getId, subCollection: "expenditure")
        }
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
                self.fetchUser(id: self.getId, subCollection: "expenditure")
            } else {
                self.fetchUser(id: self.getId, subCollection: "revenue")
            }
            self.refreshControl.endRefreshing()
        }
    }

    func setupUI() {
        // segmented control邊框
        sourceSegmentControl.layer.borderWidth = 2.0
        sourceSegmentControl.layer.borderColor = UIColor.black.cgColor
        // 預設一進去segmented所選文字為白色+黃底
        if sourceSegmentControl.selectedSegmentIndex == 0 {
            sourceSegmentControl.selectedSegmentTintColor = UIColor.systemYellow
            let segementTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            sourceSegmentControl.setTitleTextAttributes(segementTextAttributes, for: .selected)
        }
        view.backgroundColor = UIColor(red: 245/255, green: 240/255, blue: 206/255, alpha: 1)
    }

    // segmentControl
    func didSelectSegmentControl() {
        // segmentControl 偵測改值狀態
        sourceSegmentControl.addTarget(self, action: #selector(handelSegmentControl), for: .valueChanged)
    }

    // segmentControl - @objc
    @objc func handelSegmentControl() {
        // 設置segmented control被選取時文字、button顏色
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        sourceSegmentControl.setTitleTextAttributes(titleTextAttributes, for: .selected)

        // 設置對應segmentTag顏色
        segmentTag = sourceSegmentControl.selectedSegmentIndex
        switch segmentTag {
        case 1:
            sourceSegmentControl.selectedSegmentTintColor = .systemCyan
        default:
            sourceSegmentControl.selectedSegmentTintColor = .systemYellow
            sourceSegmentControl.setTitleTextAttributes(titleTextAttributes, for: .selected)
        }
        pieTableView.reloadData()
    }

// MARK: - delete功能先拿掉，因為目前重複資料會加在一起，刪除的話無法一次刪兩筆，待確認是否留
//     從firebase上刪除資料，delete firebase data需要一層一層找，不能用路徑
    func deleteSpecificData(id: String, subCollection: String, indexPathRow: Int) {
        let dataBase = Firestore.firestore()
        let documentRef = dataBase.collection("user").document(id).collection(subCollection).document(data[indexPathRow].id)
        documentRef.delete()
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
        pieChartViewDataInput()
        // 圓餅圖規格
        pieChartViewConfig()
    }

    // 圓餅圖內容
    func pieChartViewDataInput() {
// MARK: - total放全域變數整個pie顯示金額會錯誤（待找原因）
        // 用來裝整理完重複品項的資料dictionary
        var total: [String : Int] = [:]
        for num in data {
            guard let category = num.category else { return }
            if total[category] == nil {
                total[num.category ?? ""] = Int(num.amount)
            } else {
                guard var amount = total[category] else { return }
                amount += Int(num.amount) ?? 0
                total[category] = amount
            }
        }

        for num in total.keys {
            pieChartDataEntries.append(PieChartDataEntry.init(value: Double(total[num] ?? 0), label: num, icon: nil))
        }

//        print("ddddd", data)
//        print("ppppp", total)
//        print("iiiii", pieChartDataEntries)
//        print("dsdsds", totalData)
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
    func fetchUser(id: String, subCollection: String) {
        data = []
//        total = [:]
//        totalData = []
        // fetch firebase指定條件為date的資料時，用"yyyy 年 MM 月"格式來偵測
        BBCDateFormatter.shareFormatter.dateFormat = "yyyy 年 MM 月"
        let dataBase = Firestore.firestore()
        print("this is month \(BBCDateFormatter.shareFormatter.string(from: monthDatePicker.date))")
        // 抓取哪個月份由monthDatePicker.date決定
        dataBase.collection("user/\(id)/\(subCollection)")
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

        pieCell.categoryImage.image = UIImage(systemName: "hand.thumbsup.fill")
//        pieCell.nameLabel.text = totalData[indexPath.row].category//data[indexPath.row].category
//        pieCell.amountLabel.text = totalData[indexPath.row].amount//data[indexPath.row].amount
        pieCell.nameLabel.text = data[indexPath.row].category
        pieCell.amountLabel.text = data[indexPath.row].amount

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
                deleteSpecificData(id: getId, subCollection: "revenue", indexPathRow: indexPath.row)
            default:
                deleteSpecificData(id: getId,  subCollection: "expenditure", indexPathRow: indexPath.row)
            }
            data.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }
}
