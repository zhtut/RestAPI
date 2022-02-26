//
//  File.swift
//
//
//  Created by tuguang zhou on 2022/1/28.
//

import Foundation
import SSCommon
import SSLog

open class BAOrderManager {
    
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
        if let instrument = BASetup.shared.instrument {
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
    
    open class func batchOrder(batchParams: [[String: Any]], maxCount: Int = 5, completion: @escaping ([(Bool, String?)]) -> Void) {
        if batchParams.count == 0 {
            completion([(Bool, String?)]())
            return
        }
        let originParams = batchParams
        if batchParams.count > maxCount {
            var batchParams = batchParams
            var completions = [(Bool, String?)]()
            while batchParams.count > 0 {
                let top = Array(batchParams.prefix(maxCount))
                batchOrder(batchParams: top) { result in
                    completions += result
                    if completions.count == originParams.count {
                        completion(completions)
                    }
                }
                batchParams = batchParams.suffix(batchParams.count - top.count)
            }
            return
        }
        
        let path = "POST /fapi/v1/batchOrders (HMAC SHA256)"
        let params = ["batchOrders": batchParams]
        BARestAPI.sendRequestWith(path: path, params: params) { response in
            if response.responseSucceed,
               let data = response.data as? [[String: Any]] {
                var result = [(Bool, String?)]()
                for dic in data {
                    if dic.stringFor("code") != nil {
                        result.append((false, dic.stringFor("msg")))
                    } else {
                        result.append((true, nil))
                    }
                }
                completion(result)
            } else {
                var result = [(Bool, String?)]()
                for _ in batchParams {
                    result.append((false, response.errMsg))
                }
                completion(result)
            }
        }
    }
    
    @discardableResult
    open class func order(params: [String: Any], completion: @escaping SucceedHandler) -> String {
        let path = "POST /fapi/v1/order (HMAC SHA256)"
        var params = params
        var clientOrdId = ""
        if let temp = params.stringFor("newClientOrderId") {
            clientOrdId = temp
        } else {
            clientOrdId = Date.timestamp
            params["newClientOrderId"] = clientOrdId
        }
        if let side = params["side"],
        let sz = params["quantity"] {
            log("准备下单，side: \(side), 数量：\(sz)")
        }
        BARestAPI.sendRequestWith(path: path, params: params) { response in
            if response.responseSucceed {
                completion(true, nil)
            } else {
                completion(false, response.errMsg)
            }
        }
        return clientOrdId
    }
    
    // 一键清仓
    open class func closePosition(completion: @escaping SucceedHandler) {
        if let positions = BAUserWebSocket.shared.positions {
            for position in positions {
                if let positionAmt = position.positionAmt.decimalValue {
                    let isBuy = position.isBuy
                    let symbol = position.symbol
                    let sz = dabs(positionAmt)
                    let closeParams = orderParamsWith(instId: symbol,
                                                      isBuy: !isBuy,
                                                      sz: sz)
                    order(params: closeParams, completion: completion)
                }
            }
        }
    }
}