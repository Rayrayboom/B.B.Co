//
//  ViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/10/28.
//

import UIKit
import FirebaseFirestore

class ViewController: UIViewController {
    @IBAction func addData(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "AddNewData", bundle: nil)
        guard let pushAddDataPage = storyboard.instantiateViewController(
            withIdentifier: "addNewData") as? AddNewDataViewController
        else {
            fatalError("ERROR: Can not find addDataPage.")
        }

        navigationItem.backButtonTitle = ""
        navigationController?.pushViewController(pushAddDataPage, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
