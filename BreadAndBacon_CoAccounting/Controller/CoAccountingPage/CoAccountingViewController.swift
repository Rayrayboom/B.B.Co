//
//  CoAccountingViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/9.
//

import UIKit
import Charts
import FirebaseFirestore

class CoAccountingViewController: UIViewController {
    var pieChartView: PieChartView!
    var fillInPieChartView: UIView!
    // pie資料
    var pieChartDataEntries: [PieChartDataEntry] = []

    // 裝firebase上的資料
    var data: [Account] = [] {
        didSet {
            // 當資料有變動時就會去fetch一次data，當fetch data時 data就會有變動，有變動就會執行setupPieChartView來重畫pie chart
            setupPieChartView()
            bookDetailTableViewConstrains()
            bookDetailTableView.reloadData()
        }
    }

    // 當segmentTag改值時，讓對應segment的內容重新載入(重畫pie chart)
    var segmentTag: Int? {
        didSet {
            self.bookDetailTableView.reloadData()
            // 當資料有變動時就會去fetch一次data，當fetch data時 data就會有變動，有變動就會執行setupPieChartView來重畫pie chart
            setupPieChartView()
            bookDetailTableViewConstrains()
        }
    }

    // 用來存所點選之帳本的id(用來抓取對應帳本detail)
    var didSelecetedBook: String = ""

    // 用來存現有的user
    var userContent: [User] = []
    var userId: [String] = []

    @IBOutlet weak var bookDetailTableView: UITableView!
    @IBAction func addDetail(_ sender: UIButton) {
        guard let presentCoDetailVC = self.storyboard?.instantiateViewController(withIdentifier: "addCoDetailVC") as? AddCoDetailViewController
        else {
            fatalError("can not present CoDetailVC")
        }
        presentCoDetailVC.isEdit = false
        presentCoDetailVC.didSelecetedBook = didSelecetedBook
        presentCoDetailVC.modalPresentationStyle = .fullScreen
        present(presentCoDetailVC, animated: true)
    }

    @IBOutlet weak var coSegmentedControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        bookDetailTableView.delegate = self
        bookDetailTableView.dataSource = self
        setupUI()
        // 選取segment control時拿SegmentIndex
        didSelectSegmentControl()
        // 畫出view來放pieChartView
        setupfillInPieChartView()
    }

    // 當addCoDetailVC dismiss後回到coAccountingVC會呼叫viewWillAppear，重新fetch一次data並reload bookTableView
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 進入帳本內部時隱藏下方tabbar
        self.tabBarController?.tabBar.isHidden = true
        // 畫面一有變動就會去重新fetch一次data並把資料&畫面(pie + tableView)更新到最新狀態
        fetchBookDetail(document: didSelecetedBook, subCollection: "co_expenditure")
        bookDetailTableView.reloadData()
    }

    // UI
    func setupUI() {
        self.navigationItem.title = "支出總覽"
    }

    // segmentControl
    func didSelectSegmentControl() {
        coSegmentedControl.addTarget(self, action: #selector(handelSegmentControl), for: .valueChanged)
    }

    // segmentControl - @objc
    @objc func handelSegmentControl() {
        segmentTag = coSegmentedControl.selectedSegmentIndex
        print("This is current segmentTag \(segmentTag)")
        bookDetailTableView.reloadData()
    }

    // 從Firebase上fetch對應book的detail資料
    func fetchBookDetail(document: String, subCollection: String) {
        data = []
        let dataBase = Firestore.firestore()
        dataBase.collection("co-account/\(document)/\(subCollection)")
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else {
                    return
                }
                let account = snapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: Account.self)
                }
                self.data.append(contentsOf: account)
                print("book datail here \(self.data)")
            }
    }

    // 從firebase上刪除資料，delete firebase data需要一層一層找，不能用路徑
    func deleteSpecificData(document: String, subCollection: String, indexPathRow: Int) {
        let dataBase = Firestore.firestore()
        let documentRef = dataBase.collection("co-account").document(document).collection(subCollection).document(data[indexPathRow].id)
        documentRef.delete()
    }

// MARK: - Pie chart
    // 建立圓餅圖view（生成物件、位置、內容）
    func setupPieChartView() {
        // 在要畫pie chart之前先把pie的資料&subview都清空
        pieChartDataEntries = []
        // 當畫面有改變時(跳出去再回來)，把fillInPieChartView上的subvivew全部清掉（含pieChartView）
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
        switch segmentTag {
        case 1:
            // 建立一個dictionary來針對單本記帳本所有的data偵測重複的付款人並計算單人支出總和
            var total: [String : Double] = [:]
            for num in data {
                // 因為dictionary的資料 & data model的user是optional的，所以需要unwrapped
                guard let category = num.category else { return }
                // 若total裡沒有對應的人，則新增一對key:value進去
                if total[category] == nil {
                    total[num.category ?? ""] = Double(num.amount)
                } else {
                    // 若total裡已有同樣的人，就把value加上去
                    guard var amount = total[category] else { return }
                    amount += Double(num.amount) ?? 0
                    // 加完後要回傳給total
                    total[category] = amount
                }
            }
            // 把total裡的資料塞到pie chart裡
            for num in total.keys {
                pieChartDataEntries.append(PieChartDataEntry.init(value: total[num] ?? 0, label: num, icon: nil))
            }
        default:
            // 建立一個dictionary來針對單本記帳本所有的data偵測重複的付款人並計算單人支出總和
            var total: [String : Double] = [:]
            for num in data {
                // 因為dictionary的資料 & data model的user是optional的，所以需要unwrapped
                guard let user = num.user else { return }
                // 若total裡沒有對應的人，則新增一對key:value進去
                if total[user] == nil {
                    total[num.user ?? ""] = Double(num.amount)
                } else {
                    // 若total裡已有同樣的人，就把value加上去
                    guard var amount = total[user] else { return }
                    amount += Double(num.amount) ?? 0
                    // 加完後要回傳給total
                    total[user] = amount
                }
            }
            // 把total裡的資料塞到pie chart裡
            for num in total.keys {
                pieChartDataEntries.append(PieChartDataEntry.init(value: total[num] ?? 0, label: num, icon: nil))
            }
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
    func bookDetailTableViewConstrains() {
        bookDetailTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bookDetailTableView.topAnchor.constraint(equalTo: pieChartView.bottomAnchor, constant: 0),
            bookDetailTableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            bookDetailTableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            bookDetailTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
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
}

extension CoAccountingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let presentEditAddCoVC = self.storyboard?.instantiateViewController(withIdentifier: "addCoDetailVC") as? AddCoDetailViewController
        else {
            fatalError("can not find CoDetailVC")
        }
        presentEditAddCoVC.isEdit = true
        presentEditAddCoVC.tapIndexpath = indexPath
        presentEditAddCoVC.didSelecetedBook = didSelecetedBook
        // 把目前已新增的資料array傳過去addCoVC(給編輯時帶入對應資料使用)
        presentEditAddCoVC.currentData = data[indexPath.row]
        presentEditAddCoVC.modalPresentationStyle = .fullScreen
        present(presentEditAddCoVC, animated: true)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "支出明細"
    }
}

extension CoAccountingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let listCell = tableView.dequeueReusableCell(withIdentifier: "listCell") as? ListTableViewCell
        else {
            fatalError("can not create listCell")
        }

        listCell.titleLabel.text = data[indexPath.row].category
        listCell.dateLabel.text = data[indexPath.row].date
        listCell.userLabel.text = data[indexPath.row].user
        listCell.amountLabel.text = data[indexPath.row].amount
        listCell.categoryImage.image = UIImage(systemName: "hand.thumbsup.fill")

        return listCell
    }

    // tableView右滑刪除 & 連動firebase
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            // 刪除firebase資料，和下面的data.remove是順序問題，需要先偵測對應indexPath資料再進行刪除
            deleteSpecificData(document: didSelecetedBook, subCollection: "co_expenditure", indexPathRow: indexPath.row)
            data.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }
}
