//
//  AddCoDetailViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/11/10.
//

import UIKit
import FirebaseFirestore


// MARK: - expenditure
struct CoDataModel {
    var itemTextField: String = ""
    var userTextField: String = ""
    // date改用string型別存取，因為只需要存"年/月/日"，存時間"時/分"的話後續無法抓取資料
    var dateTime: String = ""
    var monthTime: String = ""
}

class AddCoDetailViewController: UIViewController {
    let sectionTitle = ["日期", "品項", "付款人"]
    var tapIndexpath: IndexPath?
    var data = CoDataModel()
    // 存付款者textField picker資料
    var userContent: [String] = ["Ray", "Jennifer"]
//    {
//        didSet {
//            print("=== this is all userContent \(self.userContent)")
//            coDetailTableView.reloadData()
//        }
//    }

    @IBOutlet weak var coDetailTableView: UITableView!
    @IBAction func dismissDetail(_ sender: UIButton) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @IBAction func saveCoDetail(_ sender: Any) {
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        coDetailTableView.delegate = self
        coDetailTableView.dataSource = self
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

extension AddCoDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
        // 把當前點到的indexPath傳到cell的indexPath
        tapIndexpath = indexPath
        // 點擊cell時收起鍵盤
        view.endEditing(true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension AddCoDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitle.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return sectionTitle[section]
        case 1:
            return sectionTitle[section]
        default:
            return sectionTitle[section]
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let coTimeCell = tableView.dequeueReusableCell(withIdentifier: "coTimeCell") as? CoTimeTableViewCell else {
                fatalError("can not create coTimeCell")
            }

            return coTimeCell
        default:
            guard let coDetailCell = tableView.dequeueReusableCell(withIdentifier: "coDetailCell") as? CoDetailTableViewCell else {
                fatalError("can not create coDetailCell")
            }

            coDetailCell.delegate = self
            coDetailCell.indexPath = indexPath
            coDetailCell.contentTextField.textAlignment = .center

            switch indexPath.section {
            case 1:
                break
            default:
                coDetailCell.content = userContent
            }

            return coDetailCell
        }
    }
}

// new coDetail cell
extension AddCoDetailViewController: CoDetailTableViewCellDelegate {
    func getInputTextField(indexPath: IndexPath, textField: String) {
        self.tapIndexpath = indexPath
        switch tapIndexpath?.section {
        case 0:
            data.itemTextField = textField
            print("======= \(data.itemTextField)")
        default:
            data.userTextField = textField
            print("======= \(data.userTextField)")
        }
    }
}
