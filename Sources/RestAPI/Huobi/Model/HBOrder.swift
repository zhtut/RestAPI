//
//  HBOrder.swift
//  SmartCurrency
//
//  Created by zhtg on 2021/8/18.
//

import Foundation

class HBOrder: Codable {
    var eventType: String? ///<    string    事件类型，有效值：trade
    var symbol: String? ///<     string    交易代码
    var tradePrice: String? ///<     string    成交价
    var tradeVolume: String? ///<     string    成交量
    var orderId: Int? ///<     long    订单ID
    var type: String? ///<     string    订单类型，有效值：buy-market, sell-market, buy-limit, sell-limit, buy-limit-maker, sell-limit-maker, var buy-ioc, sell-ioc, buy-limit-fok, sell-limit-fok
    var clientOrderId: String? ///<     string    用户自编订单号（如有）
    var orderSource: String? ///<     string    订单来源
    var orderPrice: String? ///<     string    原始订单价（市价单无效）
    var orderSize: String? ///<     string    原始订单数量（市价买单无效）
    var orderValue: String? ///<     string    原始订单金额（仅对市价买单有效）
    var tradeId: Int? ///<     long    成交ID
    var tradeTime: Int? ///<     long    成交时间
    var aggressor: Bool? ///<     bool    是否交易主动方，有效值： true (taker), false (maker)
    var orderStatus: String? ///<     string    订单状态，有效值：partial-filled, filled
    var remainAmt: String? ///<     string    该订单未成交数量（市价买单为未成交金额）
    var execAmt: String? ///<     string    该订单累计成交量（市价买单为成交金额）
}
