//
//  OKUserWebSocket.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/15.
//

import Foundation
import SSCommon
import SSLog

open class OKUserWebSocket: OKWebSocket {
    public static let shared = OKUserWebSocket()
    
    open override var urlStr: String {
        return APIKeyConfig.default.OK_WebsocketPrivateURL
    }
    
    /// 持仓对象数组
    open var positions: [OKPosition]?
    
    /// 是否有持仓
    open var hasPosition: Bool {
        if let po = positions,
           po.count > 0 {
            return true
        }
        return false
    }
    
    /// 订单
    open var orders: [OKOrder]?
    
    /// 余额
    open var balDatas: [OKBalData]?
    
    func bal(ccy: String) -> Double? {
        if let balDatas = balDatas {
            for data in balDatas {
                if data.ccy == ccy {
                    return data.availEq?.doubleValue
                }
            }
        }
        return nil
    }
    
    open var usdtBal: Double? {
        if let usdt = bal(ccy: "USDT") {
            return usdt
        }
        return nil
    }
    
    public typealias OKOrderCompletion = (Bool, String?) -> Void
    open var completions = [String: OKOrderCompletion]()
    public typealias OKBatchOrderCompletion = ([OKOrder]) -> Void
    open var batchCompletions = [String: OKBatchOrderCompletion]()
    
    /// 下单后订单变化
    public static let orderInitNotification = Notification.Name("OKOrderInitNotification")
    /// 下单后订单变化
    public static let orderChangedNotification = Notification.Name("OKOrderChangedNotification")
    /// 账号已准备好去读取
    public static let positionsInitNotification = Notification.Name("OKPositionsInitNotification")
    /// 持仓有变化
    public static let positionsChangedNotification = Notification.Name("OKPositionsChangedNotification")
    /// 余额有变化
    public static let balanceChangedNotification = Notification.Name("OKBalanceChangedNotification")
    
    public override init() {
        super.init()
        refreshOrders()
    }
    
    func refreshOrders() {
        let path = "GET /api/v5/trade/orders-pending"
        OKRestAPI.sendRequestWith(path: path, dataClass: OKOrder.self) { response in
            if response.responseSucceed {
                if let data = response.data as? [OKOrder] {
                    self.orders = data
                } else {
                    self.orders = [OKOrder]()
                }
                NotificationCenter.default.post(name: OKUserWebSocket.orderInitNotification, object: self.orders)
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    self.refreshOrders()
                }
            }
        }
    }
    
    open func login() {
        let timestamp = "\(Date().timeIntervalSince1970)"
        let method = "GET"
        let signPath = "/users/self/verify"
        let sign = OKRestAPI.OKGetSign(timestamp: timestamp, method: method, path: signPath, bodyStr: nil)
        let params = [
            "op": "login",
            "args":
                [
                    [
                        "apiKey": APIKeyConfig.default.OK_API_KEY,
                        "passphrase": APIKeyConfig.default.OK_Passphrase,
                        "timestamp": timestamp,
                        "sign": sign
                    ]
                ]
        ] as [String : Any]
        sendMessage(message: params)
    }
    
    func loginSucceed() {
        subcribeOrders()
        subcribePositions()
        subcribeAccounts()
    }
    
    open func subcribePositions() {
        subscribe(channel: "positions", instType: "ANY")
    }
    
    open func subcribeOrders() {
        subscribe(channel: "orders", instType: "ANY")
    }
    
    open func subcribeAccounts() {
        subscribe(channel: "account")
    }
    
    func processEvent(_ message: [String: Any]) {
        if let event = message["event"] as? String {
            if event == "subscribe" {
                if let arg = message["arg"] as? [String: Any],
                   let channel = arg["channel"] as? String {
                    log("\(channel)订阅成功")
                }
            } else if event == "unsubscribe" {
                if let arg = message["arg"] as? [String: Any],
                   let channel = arg["channel"] as? String {
                    log("\(channel)取消订阅成功")
                }
            } else if event == "login" {
                if let code = message["code"] as? String,
                   code == "0" {
                    log("websocket登录成功")
                    loginSucceed()
                } else {
                    let msg = message.stringFor("msg")
                    log("websocket登录失败:\(msg ?? "")")
                }
            } else if event == "error" {
                log("websocket发生错误：\(message)")
            }
        }
    }
    
    func processChannelData(_ message: [String: Any]) {
        if let arg = message["arg"] as? [String: Any],
           let channel = arg["channel"] as? String,
           let data = message["data"] as? [Any] {
            if channel == "positions" {
                var firstInit: Bool = false
                if positions == nil {
                    positions = [OKPosition]()
                    firstInit = true
                }
//                print("position message = \(message.jsonStr ?? "")")
                if let dicArray = data as? [[String: Any]] {
                    for dic in dicArray {
                        if let position = dic.transformToModel(OKPosition.self),
                        var positions = positions {
                            for (index,po) in positions.enumerated() {
                                if position.posId == po.posId {
                                    positions.remove(at: index)
                                }
                            }
                            if position.pos != "0" {
                                positions.append(position)
                            }
                            self.positions = positions
                            if firstInit {
                                NotificationCenter.default.post(name: OKUserWebSocket.positionsInitNotification, object: positions)
                            } else {
                                NotificationCenter.default.post(name: OKUserWebSocket.positionsChangedNotification, object: position)
                            }
                        }
                    }
                }
            } else if channel == "orders" {
                if self.orders == nil {
                    return
                }
                // 订单变化会从，等待成交，部分成交，完全成交
                if let dicArray = data as? [[String: Any]] {
                    for dic in dicArray {
                        if let order = dic.transformToModel(OKOrder.self),
                           var orders = orders?.filter({
                               $0.ordId != order.ordId
                           }) {
                            
                            if order.state == "live" || order.state == "partially_filled" {
                                orders.append(order)
                            }
                            self.orders = orders
                            log("订单\(order.ordId ?? "")变化：\(order.state ?? ""), \(order.msg ?? ""), \(order.code ?? "") 剩余订单数量：\(orders.count)")
                            NotificationCenter.default.post(name: OKUserWebSocket.orderChangedNotification, object: order)
                        }
                    }
                }
            } else if channel == "account" {
                if let data = data as? [[String: Any]],
                   let info = data.first,
                   let detail = info["details"] as? [[String: Any]],
                   let balDatas = detail.transformToModelArray(OKBalData.self) {
                    self.balDatas = balDatas
                }
            }
        }
    }
    
    func processOpData(_ message: [String: Any]) {
        if let op = message["op"] as? String {
            if op == "order" {
                // 这里是订单下单成功与否的通知，一般我们订单不会失败，所以这里不作操作，直接等orders订单变化的通知
                if let id = message.stringFor("id") {
                    let com = completions[id]
                    if let code = message["code"] as? String,
                       code == "0" {
                        com?(true, id)
                    } else {
                        com?(false, id)
                    }
                    log("下单结果：\(message.jsonStr ?? "")")
                    completions.removeValue(forKey: id)
                }
            } else if op == "batch-orders" || op == "batch-cancel-orders" {
                if let id = message.stringFor("id") {
                    let com = batchCompletions[id]
                    var results = [OKOrder]()
                    if let data = message["data"] as? [[String: Any]] {
                        for dic in data {
                            let order = OKOrder()
                            order.code = dic.stringFor("sCode")
                            order.msg = dic.stringFor("sMsg")
                            order.ordId = dic.stringFor("ordId")
                            results.append(order)
                        }
                    }
                    com?(results)
                    log("下单结果：\(message.jsonStr ?? "")")
                    batchCompletions.removeValue(forKey: id)
                }
            }
        }
    }
    
    open override func webSocketDidReceive(message: [String: Any]) {
        super.webSocketDidReceive(message: message)
        if let _ = message.stringFor("event") {
            processEvent(message)
        } else if let _ = message.stringFor("op") {
            processOpData(message)
        } else if let arg = message["arg"] as? [String: Any],
                  let _ = arg.stringFor("channel") {
            processChannelData(message)
        }
    }
    
    @discardableResult
    open func orderWith(order: OKOrder) -> String {
        let orderParams = order.transformToJson()
        return orderWith(params: orderParams ?? [:])
    }
    
    @discardableResult
    open func orderWith(params: [String: Any],
                   completion: OKOrderCompletion? = nil) -> String {
        var time = "\(Int(Date().timeIntervalSince1970 * 1000))"
        if let clOrdId = params["clOrdId"] as? String {
            time = clOrdId;
        }
        var newParams = params
        newParams["clOrdId"] = time
        let message = [
            "id": time,
            "op": "order",
            "args": [newParams]
        ] as [String: Any]
        sendMessage(message: message)
        if let completion = completion {
            completions[time] = completion
        }
        return time
    }
    
    @discardableResult
    open func batchOrdersWith(params: [[String: Any]],
                        completion: OKBatchOrderCompletion? = nil) -> String {
        let time = "\(Int(Date().timeIntervalSince1970 * 1000))"
        let message = [
            "id": time,
            "op": "batch-orders",
            "args": params
        ] as [String: Any]
        sendMessage(message: message)
        if let completion = completion {
            batchCompletions[time] = completion
        }
        return time
    }
    
    @discardableResult
    open func cancelBatchOrders(orders: [OKOrder],
                                completion: OKBatchOrderCompletion? = nil) -> String {
        if orders.count == 0 {
            completion?([])
            return ""
        }
        var params = [[String: Any]]()
        for order in orders {
            let param = [ "instId": order.instId ?? "",
                          "ordId": order.ordId ?? "" ]
            params.append(param)
        }
        return cancelBatchOrders(params: params, completion: completion)
    }
    
    
    @discardableResult
    open func cancelBatchOrders(params: [[String: Any]],
                                completion: OKBatchOrderCompletion? = nil) -> String {
        if params.count == 0 {
            completion?([])
            return ""
        }
        let time = "\(Int(Date().timeIntervalSince1970 * 1000))"
        let message = [
            "id": time,
            "op": "batch-cancel-orders",
            "args": params
        ] as [String: Any]
        sendMessage(message: message)
        if let completion = completion {
            batchCompletions[time] = completion
        }
        return time
    }
    
    @discardableResult
    open func closePosition(position: OKPosition,
                            completion: OKOrderCompletion? = nil) -> String {
        let params = position.closePositionParams()
        return orderWith(params: params, completion: completion)
    }

    open override func webSocketDidOpen() {
        super.webSocketDidOpen()
        login()
    }
    
    open override func webSocketDidClosedWith(code: Int, reason: String?) {
        super.webSocketDidClosedWith(code: code, reason: reason)
        positions = nil
        orders = nil
    }
}
