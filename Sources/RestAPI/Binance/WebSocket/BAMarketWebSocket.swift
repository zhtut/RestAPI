//
//  BAMarketWebSocket.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/21.
//

import Foundation
import SSCommon

class BAMarketWebSocket: BAWebSocket {

    static let shared = BAMarketWebSocket()
    
    override var urlStr: String {
        "wss://stream.binance.com:9443"
    }
    
    var completions = [String: SSSucceedHandler]()
    
    /// k线图变化的通知
    static let candleDidChangeNotification = Notification.Name("BACandleDidChangeNotification")
    
    override func webSocketDidOpen() {
        super.webSocketDidOpen()
//        subscribeCandle(symbol: "ethusdt", period: "1m")
        
        /// 订阅交易笔数
        let symbol = "ethusdt"
        let trade = "\(symbol)@trade"
        subscribe(params: [ trade ])
        
        /// 订阅深度数据
//        let depth = "\(symbol)@depth"
//        subscribe(params: [ depth ])
    }
    
    func subscribeCandle(symbol: String, period: String, completion: SSSucceedHandler? = nil) {
        let str = "\(symbol)@kline_\(period)"
        subscribe(params: [ str ])
        if completion != nil {
            /// 把回调存进字典中，key就是
            completions[str.lowercased()] = completion
        }
    }
    
    func unsubscribeCandle(symbol: String, period: String) {
        let str = "\(symbol)@kline_\(period)"
        unsubscribe(params: [ str ])
    }

    override func webSocketDidReceive(message: [String: Any]) {
        super.webSocketDidReceive(message: message)
        /*{
            "e": "kline",     // 事件类型
            "E": 123456789,   // 事件时间
            "s": "BNBBTC",    // 交易对
            "k": {
                "t": 123400000, // 这根K线的起始时间
                "T": 123460000, // 这根K线的结束时间
                "s": "BNBBTC",  // 交易对
                "i": "1m",      // K线间隔
                "f": 100,       // 这根K线期间第一笔成交ID
                "L": 200,       // 这根K线期间末一笔成交ID
                "o": "0.0010",  // 这根K线期间第一笔成交价
                "c": "0.0020",  // 这根K线期间末一笔成交价
                "h": "0.0025",  // 这根K线期间最高成交价
                "l": "0.0015",  // 这根K线期间最低成交价
                "v": "1000",    // 这根K线期间成交量
                "n": 100,       // 这根K线期间成交笔数
                "x": false,     // 这根K线是否完结(是否已经开始下一根K线)
                "q": "1.0000",  // 这根K线期间成交额
                "V": "500",     // 主动买入的成交量
                "Q": "0.500",   // 主动买入的成交额
                "B": "123456"   // 忽略此参数
            }
        } */
        if let e = message["e"] as? String,
           e == "kline" {
            processCandleMessage(message: message)
        } else if let subbed = message["subbed"] as? String {
            for key in completions.keys {
                if key == subbed {
                    let completion = completions[key]!
                    if let status = message["status"] as? String {
                        if status == "ok" {
                            completion(true, nil)
                        } else {
                            completion(false, "订阅失败：\(message["msg"] ?? "")")
                        }
                    }
                    completions.removeValue(forKey: key)
                    return
                }
            }
        }
    }
    
    func processCandleMessage(message: [String: Any]) {
        if let tick = message["k"] as? [String: Any] {
            let candle = tick.transformToModel(BACandle.self)
            NotificationCenter.default.post(name: BAMarketWebSocket.candleDidChangeNotification, object: candle)
        }
    }
}
