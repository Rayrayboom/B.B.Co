//
//  BBCoLogicManager.swift
//  BreadAndBacon_CoAccounting
//
//  Created by 張育睿 on 2022/12/1.
//

import Foundation

enum Operation: Int {
    case add = 0
    case subtract = 1
    case multiply = 2
    case divide = 3
}

class BBCoLogicManager {
    var array = [Double]()
    var currentNumber = 0.0
    var currentTag = 0.0
    
    func clear() {
        array = []
        currentNumber = 0.0
        currentTag = 0.0
    }

    // 把數字轉換為字串，對多轉換小數點後9位
    func formatToString(from num: Double) -> String {
        var formatString: String
        if String(num) == "inf" || String(num) == "nan" {
            return "Error"
        }
        
        if num != 0 {
            if (num * 1).truncatingRemainder(dividingBy: 1.0) == 0.0 {
                formatString = String(format: "%.0f", num)
            } else if (num * 10).truncatingRemainder(dividingBy: 1.0) == 0.0 {
                formatString = String(format: "%.1f", num)
            } else if (num * 100).truncatingRemainder(dividingBy: 1.0) == 0.0 {
                formatString = String(format: "%.2f", num)
            } else if (num * 1000).truncatingRemainder(dividingBy: 1.0) == 0.0 {
                formatString = String(format: "%.3f", num)
            } else if (num * 10000).truncatingRemainder(dividingBy: 1.0) == 0.0 {
                formatString = String(format: "%.4f", num)
            } else if (num * 100000).truncatingRemainder(dividingBy: 1.0) == 0.0 {
                formatString = String(format: "%.5f", num)
            } else if (num * 1000000).truncatingRemainder(dividingBy: 1.0) == 0.0 {
                formatString = String(format: "%.6f", num)
            } else if (num * 10000000).truncatingRemainder(dividingBy: 1.0) == 0.0 {
                formatString = String(format: "%.7f", num)
            } else if (num * 100000000).truncatingRemainder(dividingBy: 1.0) == 0.0 {
                formatString = String(format: "%.8f", num)
            } else {
                formatString = String(format: "%.9f", num)
            }
        } else {
            formatString = "0"
        }
        return formatString
    }
    
    func calculateArray(operation: String) -> Double? {
        if operation == "operator" {
            if array.count == 3 {
                let newValue = calculate(firstNumber: array[0], secondNumber: array[2], tag: Int(array[1]))
                array.removeAll()
                array.append(newValue)
                array.append(currentTag)
                return newValue
            }
        } else if operation == "equal" {
            if array.count == 1 || array.count == 2 {
                let newValue = calculate(firstNumber: array[0], secondNumber: currentNumber, tag: Int(currentTag))
                array.removeAll()
                array.append(newValue)
                return newValue
            }
        }
        return nil
    }
    
    // 加減乘除運算
    func calculate(firstNumber: Double, secondNumber: Double, tag: Int) -> Double {
        var total = 0.0
        if let operation = Operation(rawValue: tag) {
            switch operation {
            case .add:
                total = firstNumber + secondNumber
            case .subtract:
                total = firstNumber - secondNumber
            case .multiply:
                total = firstNumber * secondNumber
            case .divide:
                total = firstNumber / secondNumber
            }
        }
        return total
    }
}
