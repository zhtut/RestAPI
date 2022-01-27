//
//  File.swift
//  
//
//  Created by shutut on 2022/1/26.
//

import Foundation

/// 永续持仓
open class BAPosition: Codable, Equatable {
    
    public static func == (lhs: BAPosition, rhs: BAPosition) -> Bool {
        return lhs.symbol == rhs.symbol
    }
    
    open var symbol = "" //  "BTCUSDT",  // 交易对
    open var initialMargin = "" //  "0",   // 当前所需起始保证金(基于最新标记价格)
    open var maintMargin = "" //  "0", //维持保证金
    open var unrealizedProfit = "" //  "0.00000000",  // 持仓未实现盈亏
    open var positionInitialMargin = "" //  "0",  // 持仓所需起始保证金(基于最新标记价格)
    open var openOrderInitialMargin = "" //  "0",  // 当前挂单所需起始保证金(基于最新标记价格)
    open var leverage = "" //  "100",  // 杠杆倍率
    open var isolated = false //  true,  // 是否是逐仓模式
    open var entryPrice = "" //  "0.00000",  // 持仓成本价
    open var maxNotional = "" //  "250000",  // 当前杠杆下用户可用的最大名义价值
    open var bidNotional = "" //  "0",  // 买单净值，忽略
    open var askNotional = "" //  "0",  // 买单净值，忽略
    open var positionSide = "" //  "BOTH",  // 持仓方向
    open var positionAmt = "" //  "0",      // 持仓数量
    open var updateTime = 0 //  0         // 更新时间
}
