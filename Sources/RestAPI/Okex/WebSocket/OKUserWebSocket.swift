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
    
    open var positionDesc: String {
        if positions == nil || positions?.count == 0 {
            return "无持仓"
        }
        if let position = positions?.first {
            let str = position.positionDesc
            return str
        }
        return "无持仓"
    }
    
    /// 订单
    open var orders: [OKOrder]?
    
    public typealias OKOrderCompletion = (Bool, String?) -> Void
    open var completions = [String: OKOrderCompletion]()
    
    /// 下单后订单变化
    public static let orderInitNotification = Notification.Name("OKOrderInitNotification")
    /// 下单后订单变化
    public static let orderChangedNotification = Notification.Name("OKOrderChangedNotification")
    /// 账号已准备好去读取
    public static let positionsInitNotification = Notification.Name("OKPositionsInitNotification")
    /// 账户有变化
    public static let positionsChangedNotification = Notification.Name("OKPositionsChangedNotification")
    
    public override init() {
        super.init()
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
                self.subcribeOrders()
                NotificationCenter.default.post(name: OKUserWebSocket.orderInitNotification, object: self.orders)
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
        refreshOrders()
        self.subcribePositions()
    }
    
    open func subcribePositions() {
        subscribe(channel: "positions", instType: "ANY")
    }
    
    open func subcribeOrders() {
        subscribe(channel: "orders", instType: "ANY")
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
                        if let position = dic.transformToModel(OKPosition.self) {
                            for (index,po) in positions!.enumerated() {
                                if position.posId == po.posId {
                                    positions!.remove(at: index)
                                }
                            }
                            if position.pos != "0" {
                                positions!.append(position)
                            }
                            
                            if firstInit {
                                NotificationCenter.default.post(name: OKUserWebSocket.positionsInitNotification, object: positions)
                            } else {
                                NotificationCenter.default.post(name: OKUserWebSocket.positionsChangedNotification, object: position)
                                log("持仓更新：\(position.positionDesc), 最新持仓数量：\(positions!.count)")
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
                        if let order = dic.transformToModel(OKOrder.self) {
                            for (index,or) in self.orders!.enumerated() {
                                if order.ordId == or.ordId {
                                    self.orders!.remove(at: index)
                                }
                            }
                            if order.state == "live" || order.state == "partially_filled" {
                                self.orders!.append(order)
                            }
                            log("订单\(order.ordId ?? "")变化：\(order.state ?? ""), \(order.msg ?? ""), \(order.code ?? "") 剩余订单数量：\(orders!.count)")
                            NotificationCenter.default.post(name: OKUserWebSocket.orderChangedNotification, object: order)
                        }
                    }
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
            } else if op == "batch-orders" {
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
            }
        }
    }
    
    open override func webSocketDidReceive(message: [String: Any]) {
        super.webSocketDidReceive(message: message)
        if (message["event"] as? String) != nil {
            processEvent(message)
        } else if (message["op"] as? String) != nil {
            processOpData(message)
        } else if let arg = message["arg"] as? [String: Any],
                  (arg["channel"] as? String) != nil {
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
        if completion != nil {
            completions[time] = completion!
        }
        return time
    }
    
    @discardableResult
    open func batchOrdersWith(params: [[String: Any]],
                        completion: OKOrderCompletion? = nil) -> String {
        let time = "\(Int(Date().timeIntervalSince1970 * 1000))"
        let message = [
            "id": time,
            "op": "batch-orders",
            "args": params
        ] as [String: Any]
        sendMessage(message: message)
        if completion != nil {
            completions[time] = completion!
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
