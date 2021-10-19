//
//  HBCandle.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/17.
//

import Foundation

class HBCandle: Codable {
    var id: Int? ///<   long    调整为新加坡时间的时间戳，单位秒，并以此作为此K线柱的id
    var amount: Double? ///<    float    以基础币种计量的交易量
    var count: Int? ///<    integer    交易次数
    var open: Double? ///<    float    本阶段开盘价
    var close: Double? ///<    float    本阶段收盘价
    var low: Double? ///<   float    本阶段最低价
    var high: Double? ///<    float    本阶段最高价
    var vol: Double? ///<   float    以报价币种计量的交易量
    
    /// 是否上涨
    var isRise: Bool {
        return close! > open!
    }
}
