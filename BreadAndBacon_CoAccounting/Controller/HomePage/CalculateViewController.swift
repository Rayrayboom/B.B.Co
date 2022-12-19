//
//  CalculateViewController.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/12/1.
//

import UIKit

class CalculateViewController: UIViewController {
    var logic = BBCoLogicManager()
    var willClearDisplay = false
    var previousIsOperation = false
    var closure: ((String) -> (Void))?
    let blackView = UIView(frame: UIScreen.main.bounds)

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var allClearBO: UIButton!
    @IBOutlet weak var equalBO: UIButton!
    @IBOutlet weak var backgroundViewTopConatrain: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        UIView.performWithoutAnimation {
            setupUI()
        }
    }
    
    func setupUI() {
        UIView.performWithoutAnimation {
            self.equalBO.setImage(UIImage(named: "Okay"), for: .normal)
            self.equalBO.setTitle("OK", for: .normal)
            self.equalBO.layoutIfNeeded()
        }
        backgroundView.backgroundColor = UIColor().hexStringToUIColor(hex: "f3f2ef")
        backgroundView.layer.cornerRadius = 10
        backgroundViewTopConatrain.constant = CGFloat(UIScreen.main.bounds.height * 5/10)
        blackView.backgroundColor = .black
        blackView.alpha = 0
        presentingViewController?.view.addSubview(blackView)
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.5, delay: 0) {
            self.blackView.alpha = 0.3
        }
        dismissBlackViewWhenTapSpace()
    }

    func dismissBlackViewWhenTapSpace() {
        let singleFinger = UITapGestureRecognizer(
          target: self,
          action: #selector(CalculateViewController.singleTap(recognizer:)))
        singleFinger.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(singleFinger)
    }

    @objc func singleTap(recognizer: UITapGestureRecognizer){
        let point = recognizer.location(ofTouch: 0, in: recognizer.view)
        if point.y < self.view.center.y {
            self.closure?(self.label.text ?? "")
            dismiss(animated: true, completion: nil)
            self.blackView.removeFromSuperview()
        }
    }

    func labelFlashing() {
        label.alpha = 0
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
            self.label.alpha = 1
        }, completion: nil)
    }

    func reset() {
        willClearDisplay = false
        previousIsOperation = false
        logic.clear()
        label.text = "0"
        print("===", logic.array, "現在數字：", logic.currentNumber)
    }

    // AC/C
    @IBAction func clearButtonClicked(_ sender: UIButton) {
        UIView.performWithoutAnimation {
            self.allClearBO.setImage(UIImage(named: "AC"), for: .normal)
            self.allClearBO.setTitle("AC", for: .normal)
            self.allClearBO.layoutIfNeeded()
            self.equalBO.setImage(UIImage(named: "Okay"), for: .normal)
            self.equalBO.setTitle("OK", for: .normal)
            self.equalBO.layoutIfNeeded()
        }

        labelFlashing()
        reset()
    }

    // number
    @IBAction func numberButtonClicked(_ sender: UIButton) {
        UIView.performWithoutAnimation {
            self.allClearBO.setImage(UIImage(named: "C"), for: .normal)
            self.allClearBO.setTitle("C", for: .normal)
            self.allClearBO.layoutIfNeeded()
        }

        if logic.array.count == 1 || label.text == "Error" {
            reset()
            return
        }

        if willClearDisplay == true {
            label.text = ""
            willClearDisplay = false
        }

        if label.text == "0" || label.text == "00" { label.text = logic.showNumber(tag: sender.tag) }
        else {
            label.text! += logic.showNumber(tag: sender.tag)
        }
        logic.currentNumber = Double(label.text!)!
        previousIsOperation = false
        print("=== ", logic.array, "現在數字：", logic.currentNumber)
    }

    // + - × ÷
    @IBAction func operatorButtonClicked(_ sender: UIButton) {
        labelFlashing()
        UIView.performWithoutAnimation {
            self.equalBO.setImage(UIImage(named: "Equal"), for: .normal)
            self.equalBO.setTitle("=", for: .normal)
            self.equalBO.layoutIfNeeded()
        }
        if label.text == "Error" {
            reset()
            return
        }
        logic.currentTag = Double(sender.tag)

        if previousIsOperation == false {
            logic.array.append(logic.currentNumber)
            if logic.array.count == 1 {
                logic.array.append(Double(sender.tag))
            } else if let result = logic.calculateArray(operation: "operator") {
                label.text = logic.formatToString(from: result)
            }
        } else {
            if logic.array.count == 2 {
                logic.array[1] = Double(sender.tag)
            } else if logic.array.count == 1 {
                logic.array.append(Double(sender.tag))
            }
        }
        willClearDisplay = true
        previousIsOperation = true
        print("=== ", logic.array, "現在數字：",logic.currentNumber)
        print("willClearDisplay", willClearDisplay)
        print("previousIsOperation", previousIsOperation)
    }

    // =/OK
    @IBAction func equalButtonClicked(_ sender: UIButton) {
        labelFlashing()
        if label.text == "Error" {
            reset()
            return
        }
        print("willClearDisplay", willClearDisplay)
        print("previousIsOperation", previousIsOperation)
        if previousIsOperation == false {
            if sender.titleLabel?.text == "=" {
                UIView.performWithoutAnimation {
                    self.equalBO.setImage(UIImage(named: "Okay"), for: .normal)
                    self.equalBO.setTitle("OK", for: .normal)
                    self.equalBO.layoutIfNeeded()
                }
                if let result = logic.calculateArray(operation: "equal") {
                    label.text = logic.formatToString(from: result)
                }
            } else if sender.titleLabel?.text == "OK" {
                // 用clousure傳值給addNewDataCell的contentTextField
                self.closure?(self.label.text ?? "")
                self.dismiss(animated: true, completion: nil)
                // dismiss計算機後，blackView也一並dismiss
                self.blackView.removeFromSuperview()
            }
        } else if sender.titleLabel?.text == "OK" {
            // 用clousure傳值給addNewDataCell的acontentTextField
            self.closure?(self.label.text ?? "")
            self.dismiss(animated: true, completion: nil)
            // dismiss計算機後，blackView也一並dismiss
            self.blackView.removeFromSuperview()
        }
        previousIsOperation = true
        print("=== ", logic.array, "現在數字：",logic.currentNumber)
    }

    // decimals.
    @IBAction func decimalClicked(_ sender: UIButton) {
        if logic.array.count == 1 || label.text == "Error" {
            reset()
            print("=== ", logic.array, "現在數字：",logic.currentNumber)
        }

        if (label.text?.contains(".")) == false {
            label.text! += "."
        }
        previousIsOperation = false
        print("===- ", logic.array, "現在數字：",logic.currentNumber)
    }

    // +/-
    @IBAction func plusMinusClicked(_ sender: UIButton) {
        labelFlashing()

        if label.text == "Error" || label.text == "0" {
            reset()
            return
        }

        if logic.array.count == 2 {
            if previousIsOperation == false {
                logic.currentNumber *= -1
                label.text = logic.formatToString(from: logic.currentNumber)
            } else {
                logic.array[0] *= -1
                label.text = logic.formatToString(from: logic.array[0])
            }
        } else if logic.array.count == 1 {
            logic.array[0] *= -1
            label.text = logic.formatToString(from: logic.array[0])
        } else {
            logic.currentNumber *= -1
            label.text = logic.formatToString(from: logic.currentNumber)
        }
        previousIsOperation = false
        print("=== ", logic.array, "現在數字：",logic.currentNumber)
    }

    // delete
    @IBAction func deleteClicked(_ sender: UIButton) {
        labelFlashing()

        if label.text?.dropLast() == "-" || label.text?.count == 1 || label.text == "Error" {
            reset()
            return
        }

        if logic.array.count == 2 || logic.array.isEmpty {
            logic.currentNumber = Double(label.text?.dropLast() ?? "") ?? 0.0
            label.text = String(label.text?.dropLast() ?? "")
        } else if logic.array.count == 1 {
            logic.array[0] = Double(self.label.text?.dropLast() ?? "") ?? 0.0
            label.text = String(label.text?.dropLast() ?? "")
        }
        previousIsOperation = false
        print("=== ", logic.array, "現在數字：", logic.currentNumber)
    }
}
