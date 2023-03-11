//
//  BACandle.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/23.
//

import Foundation

open class BAFCandle: Codable {
    open var t: Int = 0 /// ": 123400000, // 这根K线的起始时间
    open var o: String = "" ///": "0.0010",  // 这根K线期间第一笔成交价
    open var h: String = "" ///": "0.0025",  // 这根K线期间最高成交价
    open var l: String = "" ///": "0.0015",  // 这根K线期间最低成交价
    open var c: String = "" ///": "0.0020",  // 这根K线期间末一笔成交价
    open var v: String = "" /// ": "1000",    // 这根K线期间成交量
    open var T: Int = 0 /// ": 123460000, // 这根K线的结束时间
    open var q: String = "" ///": "1.0000",  // 这根K线期间成交额
    
    open var oNum: Double {
        if let num = o.doubleValue {
            return num
        }
        return 0
    }
    
    open var hNum: Double {
        if let num = h.doubleValue {
            return num
        }
        return 0
    }
    
    open var cNum: Double {
        if let num = c.doubleValue {
            return num
        }
        return 0
    }
    
    open var lNum: Double {
        if let num = l.doubleValue {
            return num
        }
        return 0
    }
    
    /// 是否上涨
    open var isRise: Bool {
        return cNum > oNum
    }
}
