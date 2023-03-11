//
//  BAUserTrade.swift
//  
//
//  Created by zhtg on 2022/2/27.
//

import Foundation

open class BAFUserTrade: Codable {
    open var buyer = false // ": false, // 是否是买方
    open var commission = "" //  ": "-0.07819010", // 手续费
    open var commissionAsset = "" // ": "USDT", // 手续费计价单位
    open var id = 0 // ": 698759,   // 交易ID
    open var maker = false // ": false, // 是否是挂单方
    open var orderId = 0 // ": 25851813, // 订单编号
    open var price = ""  // ": "7819.01", // 成交价
    open var qty = ""  // ": "0.002", // 成交量
    open var quoteQty = ""  // ": "15.63802", // 成交额
    open var realizedPnl = ""  // ": "-0.91539999",   // 实现盈亏
    open var side = ""  // ": "SELL", // 买卖方向
    open var positionSide = ""  // ": "SHORT",  // 持仓方向
    open var symbol = ""  // ": "BTCUSDT", // 交易对
    open var time = 0  // ": 1569514978020 // 时间
}
