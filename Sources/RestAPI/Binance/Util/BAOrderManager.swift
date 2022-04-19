//
//  File.swift
//
//
//  Created by tuguang zhou on 2022/1/28.
//

import Foundation
import SSCommon
import SSLog

let newClientOrderId = "newClientOrderId"
let clientOrderId = "clientOrderId"

open class BAOrderManager {
    
    public static let shared = BAOrderManager()
    
    open var orders: [BAOrder]? {
        didSet {
            if let orders = orders {
                log("激活的订单变化：\(orders.count)")
            }
        }
    }
    
    public init() {
        let _ = NotificationCenter.default.addObserver(forName: BAUserWebSocket.orderChangedNotification, object: nil, queue: nil) { noti in
            self.orderChanged(noti: noti)
        }
        refreshOrders()
    }
    
    open func refreshOrders() {
        fetchPendingOrders { orders, errMsg in
            if let orders = orders {
                self.orders = orders
            } else {
                log("刷新订单失败")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.refreshOrders()
            }
        }
    }
    
    func fetchPendingOrders(completion: @escaping ([BAOrder]?, String?) -> Void) {
        let path = "GET /fapi/v1/openOrders (HMAC SHA256)"
        BARestAPI.sendRequestWith(path: path, dataClass: BAOrder.self) { response in
            if let data = response.data as? [BAOrder] {
                completion(data, nil)
            } else {
                completion(nil, response.errMsg)
            }
        }
    }
    
    func orderChanged(noti: Notification) {
        if let order = noti.object as? BAOrder,
           let orders = orders {
            /// 更新正在等待成交的订单
            var otherOrders = orders.filter { filter in
                return filter.clientOrderId != order.clientOrderId
            }
            if order.isWaitingFill {
                otherOrders.append(order)
            }
            self.orders = otherOrders
        }
    }
    
    func addOrderWith(params: [String: Any]) {
        if let ord = params.stringFor(newClientOrderId),
           let price = params.stringFor("price") {
            let order = BAOrder()
            order.clientOrderId = ord
            order.status = NEWING
            order.price = price
            order.symbol = params.stringFor("symbol")
            orders?.append(order)
        }
    }
    
    func removeOrderWith(params: [String: Any]) {
        if let ord = params.stringFor(newClientOrderId) {
            let other = orders?.filter({
                $0.clientOrderId != ord
            })
            self.orders = other
        }
    }
    
    func removeOrderWith(clientOrderId: String) {
        let other = orders?.filter({
            $0.clientOrderId != clientOrderId
        })
        self.orders = other
    }
    
    func removeOrderWith(orderId: Int) {
        guard orderId > 0 else {
            return
        }
        let other = orders?.filter({
            $0.orderId != orderId
        })
        self.orders = other
    }
    
    func removeAllOrder() {
        self.orders?.removeAll()
    }
    
    open class func createClientOrdId() -> String {
        let curr = Date().timeIntervalSince1970 * 1000.0 * 1000.0
        return "\(Int(curr))"
    }
    
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
        params[newClientOrderId] = createClientOrdId()
        if let instrument = BAAppSetup.shared.instrument {
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
        for orderDic in batchParams {
            self.shared.addOrderWith(params: orderDic)
        }
        BARestAPI.sendRequestWith(path: path, params: params) { response in
            if response.responseSucceed,
               let data = response.data as? [[String: Any]] {
                var result = [(Bool, String?)]()
                for (i, dic) in data.enumerated() {
                    if dic.stringFor("code") != nil {
                        result.append((false, dic.stringFor("msg")))
                        let orderDic = batchParams[i] as [String: Any]
                        self.shared.removeOrderWith(params: orderDic)
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
            clientOrdId = self.createClientOrdId()
            params["newClientOrderId"] = clientOrdId
        }
        if let side = params["side"],
           let sz = params["quantity"] {
            log("准备下单，side: \(side), 数量：\(sz)")
        }
        self.shared.addOrderWith(params: params)
        BARestAPI.sendRequestWith(path: path, params: params) { response in
            if response.responseSucceed {
                completion(true, nil)
            } else {
                self.shared.removeOrderWith(params: params)
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
    
    open class func fetchUserTrades(instId: String,
                                    startTime: String? = nil,
                                    endTime: String? = nil,
                                    fromId: Int? = nil,
                                    limit: Int? = nil,
                                    completion: @escaping ([BAUserTrade]?, String?) -> Void) {
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
        BARestAPI.sendRequestWith(path: path, params: params, dataClass: BAUserTrade.self) { response in
            if response.responseSucceed {
                if let data = response.data as? [BAUserTrade] {
                    completion(data, nil)
                }
            } else {
                completion(nil, response.errMsg)
            }
        }
    }
    
    open class func fetchHistoryOrders(instId: String,
                                       orderId: String? = nil,
                                       startTime: String? = nil,
                                       endTime: String? = nil,
                                       limit: Int? = nil,
                                       completion: @escaping ([BAOrder]?, String?) -> Void) {
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
        BARestAPI.sendRequestWith(path: path, params: params, dataClass: BAOrder.self) { response in
            if response.responseSucceed {
                if let data = response.data as? [BAOrder] {
                    completion(data, nil)
                }
            } else {
                completion(nil, response.errMsg)
            }
        }
    }
}
