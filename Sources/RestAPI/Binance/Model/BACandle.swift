//
//  BACandle.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/23.
//

import Foundation

class BACandle: Codable {
    var t: Int? /// ": 123400000, // 这根K线的起始时间
    var o: String? ///": "0.0010",  // 这根K线期间第一笔成交价
    var h: String? ///": "0.0025",  // 这根K线期间最高成交价
    var l: String? ///": "0.0015",  // 这根K线期间最低成交价
    var c: String? ///": "0.0020",  // 这根K线期间末一笔成交价
    var v: String? /// ": "1000",    // 这根K线期间成交量
    var T: Int? /// ": 123460000, // 这根K线的结束时间
    var q: String? ///": "1.0000",  // 这根K线期间成交额
    
    var oNum: Double {
        if o != nil {
            return Double(o!)!
        }
        return 0
    }
    
    var hNum: Double {
        if h != nil {
            return Double(h!)!
        }
        return 0
    }
    
    var cNum: Double {
        if c != nil {
            return Double(c!)!
        }
        return 0
    }
    
    var lNum: Double {
        if l != nil {
            return Double(l!)!
        }
        return 0
    }
    
    /// 是否上涨
    var isRise: Bool {
        return cNum > oNum
    }
    
    class func candleWith(data: [Any]) -> BACandle {
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
