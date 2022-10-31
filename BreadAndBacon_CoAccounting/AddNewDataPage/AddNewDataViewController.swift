//
//  AddNewDataViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/30.
//

import UIKit
import SwiftUI

class AddNewDataViewController: UIViewController {

    @IBOutlet weak var AddNewDadaTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AddNewDadaTableView.delegate = self
        AddNewDadaTableView.dataSource = self
        
        
//        NavigationView.toolbar {
//            ToolbarItemGroup(placement: .bottomBar) {
//                Button {
//                    
//                } label: {
//                    Image(systemName: "plus")
//                }
//            }
//        }
        
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
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row % 2 == 0 {
            let addDataCell = tableView.dequeueReusableCell(withIdentifier: "addDataCell") as! AddNewDataTableViewCell
            
            addDataCell.moneyTextField.text = ""
            addDataCell.moneyLabel.text = "金額"
            addDataCell.catagoryLabel.text = "種類"
            addDataCell.accountLabel.text = "帳戶"
            tableView.estimatedRowHeight = UITableView.automaticDimension
            
            return addDataCell
        } else {
            let addDetailCell = tableView.dequeueReusableCell(withIdentifier: "addDetailCell") as! AddNewDataTableViewCell
            tableView.rowHeight = UIScreen.main.bounds.size.height / 3
            
            
            return addDetailCell
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
}
