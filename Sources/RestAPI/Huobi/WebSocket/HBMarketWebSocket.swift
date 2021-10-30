//
//  HBMarketWebSocket.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/18.
//

import Foundation
import SSCommon

/// 现货行情
open class HBMarketWebSocket: HBWebSocket {

    public static let shared = HBMarketWebSocket()
    
    open override var urlStr: String {
        "wss://api-aws.huobi.pro/ws"
    }
    
    open var completions = [String: SSSucceedHandler]()
    
    /// k线图变化的通知
    public static let candleDidChangeNotification = Notification.Name("HBCandleDidChangeNotification")

    open override func webSocketDidOpen() {
        super.webSocketDidOpen()
    }
    
    public enum Action: String {
        case sub
        case unsub
    }
    
    open func subscribe(action: Action = .sub, str: String, completion: SSSucceedHandler? = nil) {
        let message = [
            "\(action)": str.lowercased()
        ]
        if completion != nil {
            /// 把回调存进字典中，key就是
            completions[str.lowercased()] = completion
        }
        sendMessage(message: message)
    }
    
    open func subscribeCandle(symbol: String, period: String, completion: SSSucceedHandler? = nil) {
        let str = "market.\(symbol).kline.\(period)"
        subscribe(action: .sub, str: str, completion: completion)
    }
    
    open func unsubscribeCandle(symbol: String, period: String) {
        let str = "market.\(symbol).kline.\(period)"
        subscribe(action: .unsub, str: str)
    }
    
    open override func webSocketDidReceive(message: [String : Any]) {
        super.webSocketDidReceive(message: message)
        /*
         {
         "ch": "market.ethbtc.kline.1min",
         "ts": 1489474082831, //system update time
         "tick": {
         "id": 1489464480,
         "amount": 0.0,
         "count": 0,
         "open": 7962.62,
         "close": 7962.62,
         "low": 7962.62,
         "high": 7962.62,
         "vol": 0.0
         }
         }
         */
        if let ch = message["ch"] as? String,
           ch.contains("kline") {
            processCandleMessage(message: message)
        } else if let subbed = message["subbed"] as? String {
            for key in completions.keys {
                if key == subbed {
                    let completion = completions[key]!
                    if let status = message["status"] as? String {
                        if status == "ok" {
                            completion(true, nil)
                        } else {
                            let msg = message.stringFor("message") ?? ""
                            completion(false, "订阅失败：\(msg)")
                        }
                    }
                    completions.removeValue(forKey: key)
                    return
                }
            }
        }
    }
    
    open func processCandleMessage(message: [String: Any]) {
        if let tick = message["tick"] as? [String: Any] {
            let candle = tick.transformToModel(HBCandle.self)
            NotificationCenter.default.post(name: HBMarketWebSocket.candleDidChangeNotification, object: candle)
        }
    }
}
