//
//  File.swift
//
//
//  Created by tuguang zhou on 2022/1/28.
//

import Foundation
import SSCommon
import SSLog

public let newClientOrderId = "newClientOrderId"
public let clientOrderId = "clientOrderId"

open class BAFOrderManager {
    
    /*
     GTC - Good Till Cancel 成交为止
     IOC - Immediate or Cancel 无法立即成交(吃单)的部分就撤销
     FOK - Fill or Kill 无法全部立即成交就撤销
     GTX - Good Till Crossing 无法成为挂单方就撤销
     */
    open class func orderParamsWith(instId: String,
                                    isBuy: Bool,
                                    price: Decimal? = nil,
                                    sz: Decimal) -> [String: Any] {
        var params = [String: Any]()
        params["symbol"] = instId
        params["positionSide"] = "BOTH"
        if isBuy {
            params["side"] = BUY
        } else {
            params["side"] = SELL
        }
        if let instrument = BAFAppSetup.shared.instrument {
            let sz = sz.precisionStringWith(precision:instrument.lotSz)
            params["quantity"] = sz
            if let price = price {
                params["price"] = price.precisionStringWith(precision: instrument.tickSz)
                params["type"] = "LIMIT"
                params["timeInForce"] = "GTX"
            } else {
                params["type"] = "MARKET"
            }
        }
        return params
    }
    
    @available(*, renamed: "batchOrder(batchParams:maxCount:)")
    open class func batchOrder(batchParams: [[String: Any]], maxCount: Int = 5, completion: @escaping ([(Bool, String?)]) -> Void) {
        Task {
            let result = await batchOrder(batchParams: batchParams, maxCount: maxCount)
            completion(result)
        }
    }
    
    
    open class func batchOrder(batchParams: [[String: Any]], maxCount: Int = 5) async -> [(Bool, String?)] {
        if batchParams.count == 0 {
            return [(Bool, String?)]()
        }
        let originParams = batchParams
        if batchParams.count > maxCount {
            var batchParams1 = batchParams
            var completions = [(Bool, String?)]()
            while batchParams1.count > 0 {
                let top = Array(batchParams1.prefix(maxCount))
                let result = await batchOrder(batchParams: top)
                completions += result
                if completions.count == originParams.count {
                    return completions
                }
                batchParams1 = batchParams1.suffix(batchParams1.count - top.count)
            }
            return [(Bool, String?)]()
        }
        
        let path = "POST /fapi/v1/batchOrders (HMAC SHA256)"
        let params = ["batchOrders": batchParams]
        let response = await BARestAPI.sendRequestWith(path: path, params: params)
        if response.responseSucceed,
           let data = response.data as? [[String: Any]] {
            var result = [(Bool, String?)]()
            for (_, dic) in data.enumerated() {
                if dic.stringFor("code") != nil {
                    result.append((false, dic.stringFor("msg")))
                } else {
                    result.append((true, nil))
                }
            }
            return result
        } else {
            var result = [(Bool, String?)]()
            for _ in batchParams {
                result.append((false, response.errMsg))
            }
            return result
        }
    }
    
    @discardableResult
    open class func order(params: [String: Any]) async -> (succ: Bool, errMsg: String?) {
        let path = "POST /fapi/v1/order (HMAC SHA256)"
        if let side = params["side"],
           let sz = params["quantity"] {
            log("准备下单，side: \(side), 数量：\(sz)")
        }
        let response =  await BARestAPI.sendRequestWith(path: path, params: params)
        return (response.responseSucceed, response.errMsg)
    }
    
    // 一键清仓
    open class func closePosition() async -> (succ: Bool, errMsg: String?) {
        if let positions = BAFAccountWebSocket.shared.positions {
            for position in positions {
                if let positionAmt = position.positionAmt.decimalValue {
                    let isBuy = position.isBuy
                    let symbol = position.symbol
                    let sz = dabs(positionAmt)
                    let closeParams = orderParamsWith(instId: symbol,
                                                      isBuy: !isBuy,
                                                      sz: sz)
                    return await order(params: closeParams)
                }
            }
        }
        return (false, "没有持仓，不需要清仓")
    }
    
    open class func fetchUserTrades(instId: String,
                                    startTime: String? = nil,
                                    endTime: String? = nil,
                                    fromId: Int? = nil,
                                    limit: Int? = nil) async -> ([BAFUserTrade]?, String?) {
        let path = "GET /fapi/v1/userTrades (HMAC SHA256)"
        var params = ["symbol": instId] as [String: Any]
        if let startTime = startTime,
           let timestamp = startTime.commonDate?.timestamp {
            params["startTime"] = timestamp
        }
        if let endTime = endTime,
           let timestamp = endTime.commonDate?.timestamp {
            params["endTime"] = timestamp
        }
        if let fromId = fromId {
            params["fromId"] = fromId
        }
        if let limit = limit {
            params["limit"] = limit
        }
        
        let response = await BARestAPI.sendRequestWith(path: path, params: params, dataClass: BAFUserTrade.self)
        if response.responseSucceed {
            if let data = response.res.model as? [BAFUserTrade] {
                return (data, nil)
            }
        }
        return (nil, response.errMsg)
    }
    
    open class func fetchHistoryOrders(instId: String,
                                       orderId: String? = nil,
                                       startTime: String? = nil,
                                       endTime: String? = nil,
                                       limit: Int? = nil) async -> ([BAFOrder]?, String?) {
        let path = "GET /fapi/v1/allOrders (HMAC SHA256)"
        var params = ["symbol": instId] as [String: Any]
        if let orderId = orderId {
            params["orderId"] = orderId
        }
        if let startTime = startTime,
           let timestamp = startTime.commonDate?.timestamp {
            params["startTime"] = timestamp
        }
        if let endTime = endTime,
           let timestamp = endTime.commonDate?.timestamp {
            params["endTime"] = timestamp
        }
        if let limit = limit {
            params["limit"] = limit
        }
        let response = await BARestAPI.sendRequestWith(path: path, params: params, dataClass: BAFOrder.self)
        if response.responseSucceed {
            if let data = response.res.model as? [BAFOrder] {
                return (data, nil)
            }
        }
        return (nil, response.errMsg)
    }
}
