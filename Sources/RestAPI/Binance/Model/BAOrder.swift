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
//public let LONG = "LONG"
//public let SHORT = "SHORT"

public let NEWING = "NEWING"
public let NEW = "NEW"
public let PARTIALLY_FILLED = "PARTIALLY_FILLED"
public let FILLED = "FILLED"
public let CANCELING = "CANCELING"
public let CANCELED = "CANCELED"
public let EXPIRED = "EXPIRED"
public let NEW_INSURANCE = "NEW_INSURANCE" //  风险保障基金(强平)
public let NEW_ADL = "NEW_ADL" // 自动减仓序列(强平)

open class BAOrder: Codable {
    
    open var avgPrice: String? // : "0.00000",              // 平均成交价
    open var clientOrderId: String? // ": "abc",             // 用户自定义的订单号
    open var cumQuote: String? // ": "0",                    // 成交金额
    open var executedQty: String? // ": "0",                 // 成交量
    open var orderId: Int? // ": 1573346959,              // 系统订单号
    open var origQty: String? // ": "0.40",                  // 原始委托数量
    open var origType: String? // ": "TRAILING_STOP_MARKET", // 触发前订单类型
    open var price: String? // ": "0",                       // 委托价格
    open var reduceOnly: Bool? // ": false,                // 是否仅减仓
    open var side: String? // ": "BUY",                      // 买卖方向
    open var positionSide: String? // ": "SHORT",            // 持仓方向
    open var status: String? // ": "NEW",                    // 订单状态
    open var stopPrice: String? // ": "9300",                    // 触发价，对`TRAILING_STOP_MARKET`无效
    open var closePosition: Bool? // ": false,   // 是否条件全平仓
    open var symbol: String? // ": "BTCUSDT",                // 交易对
    open var time: Int? // ": 1579276756075,              // 订单时间
    open var timeInForce: String? // ": "GTC",               // 有效方法
    open var type: String? // ": "TRAILING_STOP_MARKET",     // 订单类型
    open var activatePrice: String? // ": "9020",            // 跟踪止损激活价格, 仅`TRAILING_STOP_MARKET` 订单返回此字段
    open var priceRate: String? // ": "0.3",                 // 跟踪止损回调比例, 仅`TRAILING_STOP_MARKET` 订单返回此字段
    open var updateTime: Int? // ": 1579276756075,        // 更新时间
    open var workingType: String? // ": "CONTRACT_PRICE", // 条件价格触发类型
    open var priceProtect: Bool? // ": false            // 是否开启条件单触发保护
    
    open var isBuy: Bool {
        return side == BUY
    }
    
    /// 是否开单
//    open var isOpen: Bool {
//        if (side == BUY && positionSide == LONG) ||
//            (side == SELL && positionSide == SHORT) {
//            return true
//        }
//        return false
//    }
    
    open var isWaitingFill: Bool {
        if status == NEW ||
            status == PARTIALLY_FILLED {
            return true
        }
        return false
    }
    
    open func cancelWith(completion: @escaping SucceedHandler) {
        let path = "DELETE /fapi/v1/order (HMAC SHA256)"
        let params = ["symbol": symbol ?? "", "orderId": orderId ?? 0] as [String : Any]
        BARestAPI.sendRequestWith(path: path, params: params) { response in
            if response.responseSucceed {
                completion(true, nil)
                return
            }
            completion(false, response.errMsg)
        }
    }
    
    open class func cancel(orders: [BAOrder], maxCount: Int = 5, completion: @escaping SucceedHandler) {
        if orders.count == 0 {
            completion(true, nil)
            return
        }
        
        if orders.count > maxCount {
            var orders = orders
            while orders.count > 0 {
                let topFive = Array(orders.prefix(maxCount))
                orders = orders.suffix(orders.count - topFive.count)
                let needCompletion = orders.count <= maxCount
                cancel(orders: topFive) { succ, errMsg in
                    if needCompletion {
                        completion(succ, errMsg)
                    }
                }
            }
            return
        }
        
        let path = "DELETE /fapi/v1/batchOrders (HMAC SHA256)"
        var orderIds = [Int]()
        var clientOrderIds = [String]()
        var symbol = ""
        for or in orders {
            if let ord = or.orderId {
                orderIds.append(ord)
            } else if let clientOrderId = or.clientOrderId {
                clientOrderIds.append(clientOrderId)
            }
            if let sym = or.symbol,
               symbol == "" {
                symbol = sym
            }
        }
        
        if orderIds.count == 0 && clientOrderIds.count == 0 {
            completion(true, nil);
            return
        }
        
        let params = ["symbol": symbol, "orderIdList": orderIds, "origClientOrderIdList": clientOrderIds] as [String : Any]
        BARestAPI.sendRequestWith(path: path, params: params) { response in
            if response.responseSucceed {
                completion(true, nil)
                return
            }
            completion(false, response.errMsg)
        }
    }
    
    open class func cancelAllOrders(symbol: String, completion: @escaping SucceedHandler) {
        let path = "DELETE /fapi/v1/allOpenOrders (HMAC SHA256)"
        let params = ["symbol": symbol]
        BARestAPI.sendRequestWith(path: path, params: params) { response in
            if response.responseSucceed {
                completion(true, nil)
            } else {
                completion(false, response.errMsg)
            }
        }
    }
}
