//
//  File.swift
//  
//
//  Created by shutut on 2022/1/26.
//

import Foundation

struct BAPosition: Codable {
    var symbol = "" //  "BTCUSDT",  // 交易对
    var initialMargin = "" //  "0",   // 当前所需起始保证金(基于最新标记价格)
    var maintMargin = "" //  "0", //维持保证金
    var unrealizedProfit = "" //  "0.00000000",  // 持仓未实现盈亏
    var positionInitialMargin = "" //  "0",  // 持仓所需起始保证金(基于最新标记价格)
    var openOrderInitialMargin = "" //  "0",  // 当前挂单所需起始保证金(基于最新标记价格)
    var leverage = "" //  "100",  // 杠杆倍率
    var isolated = false //  true,  // 是否是逐仓模式
    var entryPrice = "" //  "0.00000",  // 持仓成本价
    var maxNotional = "" //  "250000",  // 当前杠杆下用户可用的最大名义价值
    var bidNotional = "" //  "0",  // 买单净值，忽略
    var askNotional = "" //  "0",  // 买单净值，忽略
    var positionSide = "" //  "BOTH",  // 持仓方向
    var positionAmt = "" //  "0",      // 持仓数量
    var updateTime = 0 //  0         // 更新时间
}
