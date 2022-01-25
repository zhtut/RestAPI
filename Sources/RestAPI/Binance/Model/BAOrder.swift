//
//  File.swift
//  
//
//  Created by tuguang zhou on 2022/1/25.
//

import Foundation
import SSCommon

public enum Side: String, Codable {
    case BUY
    case SELL
}

public enum PosSide: String, Codable {
    case LONG
    case SHORT
}

public struct BAOrder: Codable {
    
    var avgPrice = "" // : "0.00000",              // 平均成交价
    var clientOrderId = "" // ": "abc",             // 用户自定义的订单号
    var cumQuote = "" // ": "0",                    // 成交金额
    var executedQty = "" // ": "0",                 // 成交量
    var orderId = "" // ": 1573346959,              // 系统订单号
    var origQty = "" // ": "0.40",                  // 原始委托数量
    var origType = "" // ": "TRAILING_STOP_MARKET", // 触发前订单类型
    var price = "" // ": "0",                       // 委托价格
    var reduceOnly = "" // ": false,                // 是否仅减仓
    var side: Side = .BUY // ": "BUY",                      // 买卖方向
    var positionSide: PosSide = .LONG // ": "SHORT",            // 持仓方向
    var status = "" // ": "NEW",                    // 订单状态
    var stopPrice = "" // ": "9300",                    // 触发价，对`TRAILING_STOP_MARKET`无效
    var closePosition = "" // ": false,   // 是否条件全平仓
    var symbol = "" // ": "BTCUSDT",                // 交易对
    var time = "" // ": 1579276756075,              // 订单时间
    var timeInForce = "" // ": "GTC",               // 有效方法
    var type = "" // ": "TRAILING_STOP_MARKET",     // 订单类型
    var activatePrice = "" // ": "9020",            // 跟踪止损激活价格, 仅`TRAILING_STOP_MARKET` 订单返回此字段
    var priceRate = "" // ": "0.3",                 // 跟踪止损回调比例, 仅`TRAILING_STOP_MARKET` 订单返回此字段
    var updateTime = "" // ": 1579276756075,        // 更新时间
    var workingType = "" // ": "CONTRACT_PRICE", // 条件价格触发类型
    var priceProtect = "" // ": false            // 是否开启条件单触发保护
    
    /// 是否开单
    public var isOpen: Bool {
        if (side == .BUY && positionSide == .LONG) ||
            (side == .SELL && positionSide == .SHORT) {
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
