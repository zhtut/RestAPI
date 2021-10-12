//
//  OkexUserWebSocket.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/15.
//

import Foundation
import SSCommon
import SSLog

open class OkexUserWebSocket: OkexWebSocket {
    public static let shared = OkexUserWebSocket()
    
    open override var urlStr: String {
        "wss://wsaws.okex.com:8443/ws/v5/private"
    }
    
    open var balancePosition: OkexBalancePosition?
    
    /// USDT余额
    open var usdt: Double? {
        return balanceWith(ccy: "usdt")
    }
    
    /// 持仓
    open var positions: [OkexPosition]? {
        if balancePosition == nil {
            return nil
        }
        let data = balancePosition!.posData
        return data
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
    
    open var orders: [OkexOrder]?
    public typealias OkexOrderCompletion = (Bool, String?) -> Void
    open var completions = [String: OkexOrderCompletion]()
    
    /// 下单后订单变化
    public static let orderStatusChangedNotification = Notification.Name("OkexOrderStatusChangedNotification")
    /// 账号已准备好去读取
    public static let balancePositionInitReadyNotification = Notification.Name("OkexBalancePositionInitReadyNotification")
    /// 账户有变化
    public static let balancePositionChangedNotification = Notification.Name("OkexBalancePositionChangedNotification")
    
    open func login() {
        let timestamp = "\(Date().timeIntervalSince1970)"
        let method = "GET"
        let signPath = "/users/self/verify"
        let sign = OkexRestAPI.OKexGetSign(timestamp: timestamp, method: method, path: signPath, bodyStr: nil)
        let params = [
            "op": "login",
            "args":
                [
                    [
                        "apiKey": APIKeyConfig.default.OKex_API_KEY,
                        "passphrase": APIKeyConfig.default.OKex_Passphrase,
                        "timestamp": timestamp,
                        "sign": sign
                    ]
                ]
        ] as [String : Any]
        sendMessage(message: params)
    }
    
    func loginSucceed() {
        subcribeBalance()
        subcribeOrders()
    }
    
    open func subcribeBalance() {
        subscribe(channel: "balance_and_position")
    }
    
    open func subcribeOrders() {
        subscribe(channel: "orders", instType: "SPOT")
        subscribe(channel: "orders", instType: "SWAP")
        subscribe(channel: "orders", instType: "FUTURES")
    }
    
    open func balanceWith(ccy: String) -> Double? {
        if balancePosition == nil {
            return nil
        }
        for data in balancePosition!.balData! {
            if data.ccy?.lowercased() == ccy.lowercased() {
                return Double(data.cashBal ?? "0")
            }
        }
        return nil
    }
    
    open override func webSocketDidReceive(message: [String : Any]) {
        super.webSocketDidReceive(message: message)
        let event = message["event"] as? String;
        let code = message["code"] as? String;
        let op = message["op"] as? String;
        if event == "login" && code == "0" {
            log("登录成功")
            loginSucceed()
        } else if op == "order" {
            // 这里是订单下单成功与否的通知，一般我们订单不会失败，所以这里不作操作，直接等orders订单变化的通知
            if let id = message.stringFor("id") {
                let com = completions[id]
                if code == "0" {
                    com?(true, id)
                } else {
                    com?(false, id)
                }
                completions.removeValue(forKey: id)
            }
        } else {
            let arg = message["arg"] as? [String: Any]
            let data = message["data"] as? [Any]
            if arg != nil,
               let channel = arg!["channel"] as? String {
                if channel == "balance_and_position" {
                    balancePosition = nil
                    if let dic = data?.first as? [String: Any] {
                        balancePosition = dic.transformToModel(OkexBalancePosition.self)
                    }
                    if balancePosition?.eventType == "snapshot" {
                        NotificationCenter.default.post(name: OkexUserWebSocket.balancePositionInitReadyNotification, object: balancePosition)
                        log("当前OKexUSDT余额：\(self.usdt ?? 0)")
                    } else {
                        NotificationCenter.default.post(name: OkexUserWebSocket.balancePositionChangedNotification, object: balancePosition)
                    }
                } else if channel == "orders" {
                    // 订单变化会从，等待成交，部分成交，完全成交
                    var ods = [OkexOrder]()
                    if let dicArray = data as? [[String: Any]] {
                        for dic in dicArray {
                            if let order = dic.transformToModel(OkexOrder.self) {
                                ods.append(order)
                            }
                        }
                    }
                    let order = ods.first
                    NotificationCenter.default.post(name: OkexUserWebSocket.orderStatusChangedNotification, object: order)
                }
            }
        }
    }
    
    @discardableResult
    open func orderWith(order: OkexOrder) -> String {
        let orderParams = order.transformToJson()
        return orderWith(params: orderParams ?? [:])
    }
    
    @discardableResult
    open func orderWith(params: [String: Any],
                   completion: OkexOrderCompletion? = nil) -> String {
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
    open func closePosition(position: OkexPosition) -> String {
        let params = position.closePositionParams()
        return orderWith(params: params)
    }

    open override func webSocketDidOpen() {
        super.webSocketDidOpen()
        login()
    }
}
