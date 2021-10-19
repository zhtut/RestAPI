//
//  HBUserWebSocket.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/18.
//

import Foundation
import SSCommon

/// 现货账户
class HBUserWebSocket: HBWebSocket {
    
    static let shared = HBUserWebSocket()
    
    override var urlStr: String {
        "wss://api.huobi.pro/ws/v2"
    }
    
    override var gzipData: Bool {
        return false
    }
    
    var spotAccountId: Int?
    
    var accounts = [HBAccount]()
    var usdt: Double? {
        return balanceWith(ccy: "usdt")
    }
    
    var completions = [String: SSSucceedHandler]()
    
    /// 下单后订单变化
    static let orderStatusChangedNotification = Notification.Name("HBorderStatusChangedNotification")
    /// 账户有变化
    static let accountDidReadyNotification = Notification.Name("HBAccountDidReadyNotification")
    /// 账户有变化
    static let accountDidChangeNotification = Notification.Name("HBAccountDidChangeNotification")
    
    func balanceWith(ccy: String) -> Double? {
        for acc in accounts {
            if acc.currency?.uppercased() == ccy.uppercased() {
                return Double(acc.balance!)
            }
        }
        return nil
    }
    
    func subscribeAccounts() {
        let message = [
            "action": "sub",
            "ch": "accounts.update"
        ]
        sendMessage(message: message)
    }
    
    func subscribeOrder(symbol: String = "*", completion: SSSucceedHandler? = nil) {
        let ch = "orders#\(symbol)"
        let message = [
            "action": "sub",
            "ch": ch
        ]
        if completion != nil {
            /// 把回调存进字典中，key就是
            completions[ch] = completion
        }
        sendMessage(message: message)
    }
    
    func unsubscribeOrder(symbol: String = "*") {
        let message = [
            "action": "unsub",
            "ch": "orders#\(symbol)"
        ]
        sendMessage(message: message)
    }
    
    func auth() {
        log("HB.准备进行websocket登录")
        if let temp = urlStr.components(separatedBy: "//").last,
           let host = temp.components(separatedBy: "/").first {
            let path = temp.replacingOccurrences(of: host, with: "")
            var params = [String: Any]()
            params["accessKey"] = kHBAccessKey
            params["signatureMethod"] = "HmacSHA256"
            params["signatureVersion"] = "2.1"
            params["timestamp"] = Date().utcString
            
            let sign = STURLInfo.signatureWith(method: .GET, host: host, path: path, params: params)
            params["signature"] = sign
            params["authType"] = "api"
            
            var message = [
                "action": "req",
            "ch": "auth"] as [String: Any]
            message["params"] = params
            sendMessage(message: message)
        }
    }
    
    func authSucceed() {
        log("HB.登录成功，准备刷新账户ID")
        refreshAccountId()
        subscribeOrder()
    }
    
    func refreshAccountId() {
        let path = "/v1/account/accounts";
        STRestAPI.sendRequestWith(path: path, params: nil, method: .GET) { response in
            if response.responseSucceed {
                if let data = response.data as? [[String: Any]] {
                    for dic in data {
                        if let type = dic["type"] as? String,
                           type == "spot" {
                            let id = dic["id"] as? Int
                            self.spotAccountId = id
                            log("HB.账户ID刷新成功，准备进行订阅账户信息")
                            self.subscribeAccounts()
                            return
                        }
                    }
                }
            }
            self.refreshAccountId()
        }
    }
    
    override func webSocketDidOpen() {
        super.webSocketDidOpen()
        auth()
    }

    override func webSocketDidReceive(message: [String : Any]) {
        super.webSocketDidReceive(message: message)
        if let ch = message["ch"] as? String {
            if (ch == "auth") {
                let code = message["code"] as? NSNumber
                if code == 200 {
                    authSucceed()
                }
            } else if ch == "accounts.update" {
                let data = message["data"] as? [String: Any]
                if (data != nil && data!.count > 0),
                   let accountId = data!.transformToModel(HBAccount.self) {
                    if accountId.accountId != self.spotAccountId {
                        return
                    }
                    for (index,acc) in accounts.enumerated() {
                        if acc.currency == accountId.currency {
                            accounts.remove(at: index)
                            break
                        }
                    }
                    accounts.append(accountId)
                    if accountId.changeType != nil {
                        NotificationCenter.default.post(name: HBUserWebSocket.accountDidChangeNotification, object: accountId)
                    } else {
                        if accountId.currency == "usdt" {
                            NotificationCenter.default.post(name: HBUserWebSocket.accountDidReadyNotification, object: accountId)
                        }
                    }
                    
                    if accountId.currency == "usdt" {
                        log("HB.当前火币账户usdt余额：\(self.usdt ?? 0)")
                    }
                }
            } else if ch.hasPrefix("orders#") {
                if let action = message.stringFor("action") {
                    if action == "sub" {
                        if let code = message.intFor("code"),
                           let com = completions[ch] {
                            if code == 200 {
                                com(true, nil)
                            } else {
                                let msg = message.stringFor("message") ?? ""
                                com(false, "订阅失败：\(msg)")
                            }
                        }
                    } else {
                        if let data = message["data"] as? [String: Any] {
                            if let order = data.transformToModel(HBOrder.self) {
                                NotificationCenter.default.post(name: HBUserWebSocket.orderStatusChangedNotification, object: order)
                            }
                        } 
                    }
                }
            }
        }
    }
}
