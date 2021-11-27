//
//  BACandle.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/23.
//

import Foundation

open class BACandle: Codable {
    open var t: Int? /// ": 123400000, // 这根K线的起始时间
    open var o: String? ///": "0.0010",  // 这根K线期间第一笔成交价
    open var h: String? ///": "0.0025",  // 这根K线期间最高成交价
    open var l: String? ///": "0.0015",  // 这根K线期间最低成交价
    open var c: String? ///": "0.0020",  // 这根K线期间末一笔成交价
    open var v: String? /// ": "1000",    // 这根K线期间成交量
    open var T: Int? /// ": 123460000, // 这根K线的结束时间
    open var q: String? ///": "1.0000",  // 这根K线期间成交额
    
    open var oNum: Double {
        if o != nil {
            return Double(o!) ?? 0.0
        }
        return 0
    }
    
    open var hNum: Double {
        if h != nil {
            return Double(h!) ?? 0.0
        }
        return 0
    }
    
    open var cNum: Double {
        if c != nil {
            return Double(c!) ?? 0.0
        }
        return 0
    }
    
    open var lNum: Double {
        if l != nil {
            return Double(l!) ?? 0.0
        }
        return 0
    }
    
    /// 是否上涨
    open var isRise: Bool {
        return cNum > oNum
    }
    
    open class func candleWith(data: [Any]) -> BACandle {
        let candle = BACandle()
        if data.count > 7 {
            candle.t = data[0] as? Int /// ": 123400000, // 这根K线的起始时间
            candle.o = data[1] as? String ///": "0.0010",  // 这根K线期间第一笔成交价
            candle.h = data[2] as? String ///": "0.0025",  // 这根K线期间最高成交价
            candle.l = data[3] as? String ///": "0.0015",  // 这根K线期间最低成交价
            candle.c = data[4] as? String ///": "0.0020",  // 这根K线期间末一笔成交价
            candle.v = data[5] as? String /// ": "1000",    // 这根K线期间成交量
            candle.T = data[6] as? Int /// ": 123460000, // 这根K线的结束时间
            candle.q = data[7] as? String ///": "1.0000",  // 这根K线期间成交额
        }
        return candle
    }
}
