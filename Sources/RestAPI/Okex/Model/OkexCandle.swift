//
//  OkexCandle.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/15.
//

import Foundation

/// k线图，蜡烛图
public struct OkexCandle: Codable {
    public var instId    : String? ///<     symbol
    public var ts    : String? ///<     开始时间，Unix时间戳的毫秒数格式，如 1597026383085
    public var o    : String? ///<     开盘价格
    public var h    : String? ///<     最高价格
    public var l    : String? ///<     最低价格
    public var c    : String? ///<     收盘价格
    public var vol    : String? ///<     交易量，以张为单位
    // 如果是衍生品合约，数值为合约的张数。
    // 如果是币币/币币杠杆，数值为交易货币的数量。
    public var volCcy    : String? ///<     交易量，以币为单位
    // 如果是衍生品合约，数值为结算货币的数量。
    // 如果是币币/币币杠杆，数值为计价货币的数量。
    
    public var oNum: Double {
        if o != nil {
            return Double(o!)!
        }
        return 0
    }
    
    public var hNum: Double {
        if h != nil {
            return Double(h!)!
        }
        return 0
    }
    
    public var cNum: Double {
        if c != nil {
            return Double(c!)!
        }
        return 0
    }
    
    public var lNum: Double {
        if l != nil {
            return Double(l!)!
        }
        return 0
    }
    
    public var offset: Double {
        if oNum == 0 {
            return 0
        }
        return (cNum - oNum) * 100.0 / oNum
    }
    
    /// 是否上涨
    public var isRise: Bool {
        return cNum > oNum
    }
    
    public static func candleWith(data: [String]) -> OkexCandle {
        var candle = OkexCandle()
        if data.count >= 5 {
            candle.ts = data[0]
            candle.o = data[1]
            candle.h = data[2]
            candle.l = data[3]
            candle.c = data[4]
            
            if data.count > 5 {
                candle.vol = data[5]
            }
            if data.count > 6 {
                candle.volCcy = data[6]
            }
        }
        return candle
    }
    
    public var price: Double? {
        let total = cNum * 0.3 + oNum * 0.3 + hNum * 0.2 + lNum * 0.2
        return total
    }
}

public extension Array where Element == OkexCandle {
    
    func maValueWith(count: Int) -> Double {
        if (self.count > count) {
            var index = count - 1
            var average = 0.0
            while(index >= 0) {
                let candle = self[index]
                if let price = candle.price {
                    average = (average * Double((count - index - 1)) + price) / Double((count - index))
                }
                index -= 1
            }
            return average
        }
        
        return 0
    }
}
