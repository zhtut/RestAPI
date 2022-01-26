//
//  File.swift
//  
//
//  Created by tuguang zhou on 2022/1/25.
//

import Foundation
import SSCommon

public let BUY = "BUY"
public let SELL = "SELL"
public let LONG = "LONG"
public let SHORT = "SHORT"

public let NEW = "NEW"
public let PARTIALLY_FILLED = "PARTIALLY_FILLED"
public let FILLED = "FILLED"
public let CANCELED = "CANCELED"
public let EXPIRED = "EXPIRED"
public let NEW_INSURANCE = "NEW_INSURANCE" //  风险保障基金(强平)
public let NEW_ADL = "NEW_ADL" // 自动减仓序列(强平)

public struct BAOrder: Codable {
    
    public var avgPrice = "" // : "0.00000",              // 平均成交价
    public var clientOrderId = "" // ": "abc",             // 用户自定义的订单号
    public var cumQuote = "" // ": "0",                    // 成交金额
    public var executedQty = "" // ": "0",                 // 成交量
    public var orderId = "" // ": 1573346959,              // 系统订单号
    public var origQty = "" // ": "0.40",                  // 原始委托数量
    public var origType = "" // ": "TRAILING_STOP_MARKET", // 触发前订单类型
    public var price = "" // ": "0",                       // 委托价格
    public var reduceOnly = "" // ": false,                // 是否仅减仓
    public var side = "" // ": "BUY",                      // 买卖方向
    public var positionSide = "" // ": "SHORT",            // 持仓方向
    public var status = "" // ": "NEW",                    // 订单状态
    public var stopPrice = "" // ": "9300",                    // 触发价，对`TRAILING_STOP_MARKET`无效
    public var closePosition = "" // ": false,   // 是否条件全平仓
    public var symbol = "" // ": "BTCUSDT",                // 交易对
    public var time = "" // ": 1579276756075,              // 订单时间
    public var timeInForce = "" // ": "GTC",               // 有效方法
    public var type = "" // ": "TRAILING_STOP_MARKET",     // 订单类型
    public var activatePrice = "" // ": "9020",            // 跟踪止损激活价格, 仅`TRAILING_STOP_MARKET` 订单返回此字段
    public var priceRate = "" // ": "0.3",                 // 跟踪止损回调比例, 仅`TRAILING_STOP_MARKET` 订单返回此字段
    public var updateTime = "" // ": 1579276756075,        // 更新时间
    public var workingType = "" // ": "CONTRACT_PRICE", // 条件价格触发类型
    public var priceProtect = "" // ": false            // 是否开启条件单触发保护
    
    /// 是否开单
    public var isOpen: Bool {
        if (side == BUY && positionSide == LONG) ||
            (side == SELL && positionSide == SHORT) {
            return true
        }
        return false
    }
    
    public func cancelWith(completion: @escaping SSSucceedHandler) {
        let path = "DELETE /fapi/v1/order (HMAC SHA256)"
        let params = ["symbol": symbol, "orderId": orderId]
        BARestAPI.sendRequestWith(path: path, params: params) { response in
            if response.responseSucceed {
                completion(true, nil)
                return
            }
            completion(false, response.errMsg)
        }
    }
    
    public static func cancel(orders: [BAOrder], completion: @escaping SSSucceedHandler) {
        if orders.count == 0 {
            completion(true, nil)
            return
        }
        let path = "DELETE /fapi/v1/batchOrders (HMAC SHA256)"
        var orderIds = [String]()
        for or in orders {
            orderIds.append(or.orderId)
        }
        var symbol = ""
        if let first = orders.first {
            symbol = first.symbol
        }
        let params = ["symbol": symbol, "orderIdList": orderIds] as [String : Any]
        BARestAPI.sendRequestWith(path: path, params: params) { response in
            if response.responseSucceed {
                completion(true, nil)
                return
            }
            completion(false, response.errMsg)
        }
        
    }
}
