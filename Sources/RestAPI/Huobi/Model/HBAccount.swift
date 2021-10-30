//
//  HBAccountID.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/17.
//

import Foundation

open class HBAccount: Codable {
    open var currency: String? ///<    string    币种
    open var accountId: Int? ///<    long    账户ID
    open var balance: String? ///<    string    账户余额（仅当账户余额发生变动时推送）
    open var available: String? ///<    string    可用余额（仅当可用余额发生变动时推送）
    open var changeType: String? ///<    string    余额变动类型，有效值：order-place(订单创建)，order-match(订单成交)，order-refund(订单成交退款)，order-cancel(订单撤销)，order-fee-refund(点卡抵扣交易手续费)，margin-transfer(杠杆账户划转)，margin-loan(借币本金)，margin-interest(借币计息)，margin-repay(归还借币本金币息)，deposit (充币）, withdraw (提币)，other(其他资产变化)
    open var accountType: String? ///<    string    账户类型，有效值：trade, loan, interest
    open var changeTime: Int? ///<    long    余额变动时间，unix time in millisecond
}
