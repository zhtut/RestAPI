//
//  File.swift
//
//
//  Created by tuguang zhou on 2022/1/26.
//

import Foundation

/// 资产
open class BAFAsset: Codable, Equatable {
    public static func == (lhs: BAFAsset, rhs: BAFAsset) -> Bool {
        return lhs.asset == rhs.asset
    }
    
    open var asset = "" //  "USDT",        //资产
    open var walletBalance = "" //  "23.72469206",  //余额
    open var unrealizedProfit = "" //  "0.00000000",  // 未实现盈亏
    open var marginBalance = "" //  "23.72469206",  // 保证金余额
    open var maintMargin = "" //  "0.00000000",    // 维持保证金
    open var initialMargin = "" //  "0.00000000",  // 当前所需起始保证金
    open var positionInitialMargin = "" //  "0.00000000",  // 持仓所需起始保证金(基于最新标记价格)
    open var openOrderInitialMargin = "" //  "0.00000000", // 当前挂单所需起始保证金(基于最新标记价格)
    open var crossWalletBalance = "" //  "23.72469206",  //全仓账户余额
    open var crossUnPnl = "" //  "0.00000000" // 全仓持仓未实现盈亏
    open var availableBalance = "" //  "23.72469206",       // 可用余额
    open var maxWithdrawAmount = "" //  "23.72469206",     // 最大可转出余额
    open var marginAvailable = true //  true,   // 是否可用作联合保证金
    open var updateTime = 0 //  1625474304765  //更新时间
}
