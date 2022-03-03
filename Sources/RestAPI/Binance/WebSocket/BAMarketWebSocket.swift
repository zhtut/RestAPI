//
//  BAMarketWebSocket.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/21.
//

import Foundation
import SSCommon
import SSLog

open class BAMarketWebSocket: BAWebSocket {
    
    public static let shared = BAMarketWebSocket()
    
    open override var urlStr: String {
        return APIKeyConfig.default.BA_Websocket_URL_Str
    }
    
    var orderBook = BAOrderBook()
    
    /// k线图变化的通知
    public static let candleDidChangeNotification = Notification.Name("BACandleDidChangeNotification")
    /// 最新买卖价变化的通知
    public static let bookTickerDidChangeNotification = Notification.Name("BABookTickerDidChangeNotification")
    
    open override func webSocketDidOpen() {
        super.webSocketDidOpen()
    }
    
    /*
     m -> 分钟; h -> 小时; d -> 天; w -> 周; M -> 月
     1m
     3m
     5m
     15m
     30m
     1h
     2h
     4h
     6h
     8h
     12h
     1d
     3d
     1w
     1M
     */
    open func subscribeCandle(symbol: String, period: String) {
        let str = "\(symbol.lowercased())@kline_\(period)"
        subscribe(params: [ str ])
    }
    
    open func unsubscribeCandle(symbol: String, period: String) {
        let str = "\(symbol.lowercased())@kline_\(period)"
        unsubscribe(params: [ str ])
    }

    open override func webSocketDidReceive(message: [String: Any]) {
        super.webSocketDidReceive(message: message)
//        log("BAMarket.didReceiveMessageWith:\(message.jsonStr ?? "")")
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
        if let stream = message.stringFor("stream") {
            if stream.hasSuffix("@bookTicker") {
                processBookTicker(message: message)
            } else if stream.contains("kline") {
                processCandleMessage(message: message)
            } else if stream.contains("depth") {
                processOrderBook(message: message)
            }
        }
    }
    
    func processCandleMessage(message: [String: Any]) {
        if let data = message["data"] as? [String: Any],
           let tick = data["k"] as? [String: Any] {
            let candle = tick.transformToModel(BACandle.self)
            NotificationCenter.default.post(name: BAMarketWebSocket.candleDidChangeNotification, object: candle)
        }
    }
    
    // MARK: BookTicker
    
    open func subBookTicker(symbol: String) {
        orderBook.instId = symbol
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
    
    // MARK: OrderBook
    open func subOrderBook(symbol: String) {
        let streamName = "\(symbol.lowercased())@depth"
        subscribe(params: [streamName])
    }
    
    open func unsubOrderBook(symbol: String) {
        let streamName = "\(symbol.lowercased())@depth"
        unsubscribe(params: [streamName])
    }
    
    /*
     2022-03-03 20:05:01:BAMarket.didReceiveMessageWith:["data": {
     E = 1646309101352;
     T = 1646309101331;
     U = 1257016466251;
     a =     (
     (
     "2917.66",
     "0.003"
     ),
     (
     "2917.67",
     "0.000"
     ),
     (
     "2917.69",
     "0.002"
     ),
     (
     "2917.75",
     "0.000"
     ),
     (
     "2917.76",
     "1.022"
     ),
     (
     "2917.77",
     "0.517"
     ),
     (
     "2917.78",
     "0.000"
     ),
     (
     "2917.79",
     "0.031"
     ),
     (
     "2917.91",
     "0.034"
     ),
     (
     "2918.98",
     "0.003"
     ),
     (
     "2919.13",
     "4.370"
     ),
     (
     "2921.24",
     "0.000"
     )
     );
     b =     (
     (
     "2891.41",
     "0.000"
     ),
     (
     "2914.68",
     "0.000"
     ),
     (
     "2914.69",
     "0.299"
     ),
     (
     "2916.69",
     "7.413"
     ),
     (
     "2916.71",
     "4.022"
     ),
     (
     "2916.72",
     "0.517"
     ),
     (
     "2916.80",
     "5.250"
     ),
     (
     "2917.40",
     "0.000"
     ),
     (
     "2917.41",
     "12.731"
     )
     );
     e = depthUpdate;
     pu = 1257016466051;
     s = ETHBUSD;
     u = 1257016472748;
     }, "stream": ethbusd@depth]
     */
    func processOrderBook(message: [String: Any]) {
        orderBook.update(message: message)
    }
}
