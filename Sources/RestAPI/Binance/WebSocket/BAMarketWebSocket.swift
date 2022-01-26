//
//  BAMarketWebSocket.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/21.
//

import Foundation
import SSCommon

open class BAMarketWebSocket: BAWebSocket {
    
    public static let shared = BAMarketWebSocket()
    
    open override var urlStr: String {
        return APIKeyConfig.default.BA_Websocket_URL_Str
    }
    
    var completions = [String: SSSucceedHandler]()
    
    /// k线图变化的通知
    public static let candleDidChangeNotification = Notification.Name("BACandleDidChangeNotification")
    /// 最新买卖价变化的通知
    public static let bookTickerDidChangeNotification = Notification.Name("BABookTickerDidChangeNotification")
    
    open override func webSocketDidOpen() {
        super.webSocketDidOpen()
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

    open override func webSocketDidReceive(message: [String: Any]) {
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
        } else if let stream = message.stringFor("stream") {
            if stream.hasSuffix("@bookTicker") {
                processBookTicker(message: message)
            }
        }
    }
    
    func processCandleMessage(message: [String: Any]) {
        if let tick = message["k"] as? [String: Any] {
            let candle = tick.transformToModel(BACandle.self)
            NotificationCenter.default.post(name: BAMarketWebSocket.candleDidChangeNotification, object: candle)
        }
    }
    
    open func subBookTicker(symbol: String) {
        let streamName = "\(symbol.lowercased())@bookTicker"
        subscribe(params: [streamName])
    }
    
    open func unsubBookTicker(symbol: String) {
        let streamName = "\(symbol.lowercased())@bookTicker"
        unsubscribe(params: [streamName])
    }
    
    /*
     {"stream":"ethbusd@bookTicker","data":{"e":"bookTicker","u":1154786566700,"s":"ETHBUSD","b":"2450.03","B":"2.346","a":"2450.04","A":"1.626","T":1643162839528,"E":1643162839533}}
     */
    func processBookTicker(message: [String: Any]) {
        if let data = message["data"] as? [String: Any],
           let bookTicker = data.transformToModel(BABookTicker.self) {
            NotificationCenter.default.post(name: BAMarketWebSocket.bookTickerDidChangeNotification, object: bookTicker)
        }
    }
}
