//
//  AddNewDataViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/30.
//

import UIKit
import SwiftUI

class AddNewDataViewController: UIViewController {
    let category: [String] = ["時間", "金額", "種類", "帳戶", ""]

    @IBOutlet weak var addNewDadaTableView: UITableView!

    @IBOutlet weak var sourceSegmentControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        addNewDadaTableView.delegate = self
        addNewDadaTableView.dataSource = self
        addNewDadaTableView.estimatedRowHeight = UITableView.automaticDimension

        // segmentControl 偵測改值狀態
        sourceSegmentControl.addTarget(self, action: #selector(handelSegmentControl), for: .valueChanged)
    }

    // func for segmentControl 更改時切換頁面
    @objc func handelSegmentControl() {
        print(sourceSegmentControl.selectedSegmentIndex)

//        switch sourceSegmentControl.selectedSegmentIndex {
//        case 0:
//            
//        case 1:
//            
//        default:
//            <#code#>
//        }
    addNewDadaTableView.reloadData()
    }
}

extension AddNewDataViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
    }


//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return
//    }
}

extension AddNewDataViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return category.count
        } else if section == 2 {
            return 1
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let dateCell = tableView.dequeueReusableCell(
                withIdentifier: "dateCell") as? AddNewDataTableViewCell
            else {
                fatalError("can not create cell")
            }
            dateCell.dateLabel.text = ""
            return dateCell
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                guard let addDataCell = tableView.dequeueReusableCell(
                    withIdentifier: "addDataCell") as? AddNewDataTableViewCell
                else {
                    fatalError("can not create cell")
                }

                addDataCell.fillInContent(name: category[indexPath.row])
                return addDataCell
            } else if indexPath.row == 1 {
                guard let addDataCell = tableView.dequeueReusableCell(
                    withIdentifier: "addDataCell") as? AddNewDataTableViewCell
                else {
                    fatalError("can not create cell")
                }

                addDataCell.fillInContent(name: category[indexPath.row])
                return addDataCell
            } else if indexPath.row == 2 {
                guard let addDataCell = tableView.dequeueReusableCell(
                    withIdentifier: "addDataCell") as? AddNewDataTableViewCell
                else {
                    fatalError("can not create cell")
                }

                addDataCell.fillInContent(name: category[indexPath.row])
                return addDataCell
            } else {
                guard let addDataCell = tableView.dequeueReusableCell(
                    withIdentifier: "addDataCell") as? AddNewDataTableViewCell
                else {
                    fatalError("can not create cell")
                }

                addDataCell.fillInContent(name: category[indexPath.row])
                return addDataCell
            }
        } else if indexPath.section == 2 {
            guard let qrCell = tableView.dequeueReusableCell(
                withIdentifier: "QRCell") as? AddNewDataTableViewCell
            else {
                fatalError("can not create cell")
            }
            qrCell.dateLabel.text = ""
            return qrCell
        } else {
            if indexPath.row == 0 {
                guard let detailCell = tableView.dequeueReusableCell(
                    withIdentifier: "detailCell") as? AddNewDataTableViewCell
                else {
                    fatalError("can not create cell")
                }
                detailCell.detailTextView.text = "711"
                return detailCell
            } else {
                guard let detailCell = tableView.dequeueReusableCell(
                    withIdentifier: "detailCell") as? AddNewDataTableViewCell
                else {
                    fatalError("can not create cell")
                }
                detailCell.detailTextView.text = "711"
//                tableView.rowHeight = 300
                return detailCell
            }
        }
    }
}
