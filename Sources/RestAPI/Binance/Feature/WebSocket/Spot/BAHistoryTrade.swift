//
//  File.swift
//  
//
//  Created by zhtg on 2022/4/4.
//

import Foundation

/// 市场交易记录
public struct BAHistoryTrade: Codable {
    public var e: String? ///< ": "trade",     // 事件类型
    public var E: Int? ///< ": 123456789,   // 事件时间
    public var s: String? ///< ": "BNBBTC",    // 交易对
    public var t: Int? ///< ": 12345,       // 交易ID
    public var p: String? ///< ": "0.001",     // 成交价格
    public var q: String? ///< ": "100",       // 成交数量
    public var b: Int? ///< ": 88,          // 买方的订单ID
    public var a: Int? ///< ": 50,          // 卖方的订单ID
    public var T: Int? ///< ": 123456785,   // 成交时间
    public var m: Bool? ///< ": true,        // 买方是否是做市方。如true，则此次成交是一个主动卖出单，否则是一个主动买入单。
    public var M: Bool? ///< ": true         // 请忽略该字段
}
