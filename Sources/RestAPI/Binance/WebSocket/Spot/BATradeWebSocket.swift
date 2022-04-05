//
//  BAMarketWebSocket.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/21.
//

import Foundation
import SSCommon
import SSLog

open class BATradeWebSocket: BAWebSocket {
    
    open var instId = ""
    
    public convenience init(instId: String) {
        self.init()
        self.instId = instId
        self.open()
    }
    
    open override var urlStr: String {
        return "wss://stream.binance.com:9443/ws/\(instId.lowercased())@trade"
    }
    
    /// k线图变化的通知
    public static let tradeDidChangeNotification = Notification.Name("BATradeDidChangeNotification")
    
    open override func webSocketDidReceive(message: [String: Any]) {
        super.webSocketDidReceive(message: message)
//        log("TradeWebSocket.didReceiveMessageWith:\(message.jsonStr ?? "")")
        /*{
         "q" : "0.00067000",
         "t" : 1312486485,
         "M" : true,
         "E" : 1648828827635,
         "p" : "46566.99000000",
         "e" : "trade",
         "T" : 1648828827634,
         "s" : "BTCUSDT",
         "b" : 10041835161,
         "a" : 10041835278,
         "m" : true
         } */
        if let e = message.stringFor("e"),
           e == "trade",
           let tradeItem = message.transformToModel(BAHistoryTrade.self) {
            NotificationCenter.default.post(name: BATradeWebSocket.tradeDidChangeNotification, object: tradeItem)
        }
    }
    
    /*
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "s" : "BTCUSDT",
     "E" : 1648828827450,
     "p" : "46566.99000000",
     "T" : 1648828827449,
     "M" : true,
     "a" : 10041835266,
     "b" : 10041835161,
     "t" : 1312486482,
     "e" : "trade",
     "q" : "0.00081000",
     "m" : true
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "s" : "BTCUSDT",
     "t" : 1312486482,
     "m" : true,
     "a" : 10041835266,
     "p" : "46566.99000000",
     "T" : 1648828827449,
     "M" : true,
     "e" : "trade",
     "E" : 1648828827450,
     "q" : "0.00081000",
     "b" : 10041835161
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "s" : "BTCUSDT",
     "t" : 1312486483,
     "m" : true,
     "a" : 10041835269,
     "p" : "46566.99000000",
     "T" : 1648828827467,
     "M" : true,
     "e" : "trade",
     "E" : 1648828827468,
     "q" : "0.00070000",
     "b" : 10041835161
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "s" : "BTCUSDT",
     "t" : 1312486482,
     "m" : true,
     "a" : 10041835266,
     "p" : "46566.99000000",
     "T" : 1648828827449,
     "M" : true,
     "e" : "trade",
     "E" : 1648828827450,
     "q" : "0.00081000",
     "b" : 10041835161
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "s" : "BTCUSDT",
     "E" : 1648828827468,
     "e" : "trade",
     "m" : true,
     "b" : 10041835161,
     "T" : 1648828827467,
     "t" : 1312486483,
     "M" : true,
     "p" : "46566.99000000",
     "q" : "0.00070000",
     "a" : 10041835269
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "error" : {
     "msg" : "Invalid JSON: expected value at line 1 column 1",
     "code" : 3
     }
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "a" : 10041835270,
     "t" : 1312486484,
     "T" : 1648828827490,
     "b" : 10041835161,
     "p" : "46566.99000000",
     "m" : true,
     "q" : "0.00500000",
     "e" : "trade",
     "E" : 1648828827490,
     "M" : true,
     "s" : "BTCUSDT"
     }
     2022-04-02 00:00:27:websocket断开连接wss://stream.binance.com:9443/ws/btcusdt@trade，code: 1008，原因：Invalid request
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "q" : "0.00070000",
     "t" : 1312486483,
     "M" : true,
     "E" : 1648828827468,
     "p" : "46566.99000000",
     "e" : "trade",
     "T" : 1648828827467,
     "s" : "BTCUSDT",
     "b" : 10041835161,
     "a" : 10041835269,
     "m" : true
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "q" : "0.00070000",
     "t" : 1312486483,
     "M" : true,
     "E" : 1648828827468,
     "p" : "46566.99000000",
     "e" : "trade",
     "T" : 1648828827467,
     "s" : "BTCUSDT",
     "b" : 10041835161,
     "a" : 10041835269,
     "m" : true
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "s" : "BTCUSDT",
     "a" : 10041835270,
     "b" : 10041835161,
     "t" : 1312486484,
     "M" : true,
     "e" : "trade",
     "m" : true,
     "p" : "46566.99000000",
     "q" : "0.00500000",
     "T" : 1648828827490,
     "E" : 1648828827490
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "q" : "0.00500000",
     "E" : 1648828827490,
     "a" : 10041835270,
     "b" : 10041835161,
     "e" : "trade",
     "T" : 1648828827490,
     "p" : "46566.99000000",
     "m" : true,
     "M" : true,
     "t" : 1312486484,
     "s" : "BTCUSDT"
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "q" : "0.00070000",
     "E" : 1648828827468,
     "a" : 10041835269,
     "b" : 10041835161,
     "e" : "trade",
     "T" : 1648828827467,
     "p" : "46566.99000000",
     "m" : true,
     "M" : true,
     "t" : 1312486483,
     "s" : "BTCUSDT"
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "T" : 1648828827490,
     "m" : true,
     "q" : "0.00500000",
     "M" : true,
     "b" : 10041835161,
     "t" : 1312486484,
     "s" : "BTCUSDT",
     "p" : "46566.99000000",
     "a" : 10041835270,
     "E" : 1648828827490,
     "e" : "trade"
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "q" : "0.00500000",
     "t" : 1312486484,
     "M" : true,
     "E" : 1648828827490,
     "p" : "46566.99000000",
     "e" : "trade",
     "T" : 1648828827490,
     "s" : "BTCUSDT",
     "b" : 10041835161,
     "a" : 10041835270,
     "m" : true
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "q" : "0.00500000",
     "t" : 1312486484,
     "M" : true,
     "E" : 1648828827490,
     "p" : "46566.99000000",
     "e" : "trade",
     "T" : 1648828827490,
     "s" : "BTCUSDT",
     "b" : 10041835161,
     "a" : 10041835270,
     "m" : true
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "q" : "0.00067000",
     "t" : 1312486485,
     "M" : true,
     "E" : 1648828827635,
     "p" : "46566.99000000",
     "e" : "trade",
     "T" : 1648828827634,
     "s" : "BTCUSDT",
     "b" : 10041835161,
     "a" : 10041835278,
     "m" : true
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "q" : "0.00067000",
     "t" : 1312486485,
     "M" : true,
     "E" : 1648828827635,
     "p" : "46566.99000000",
     "e" : "trade",
     "T" : 1648828827634,
     "s" : "BTCUSDT",
     "b" : 10041835161,
     "a" : 10041835278,
     "m" : true
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "q" : "0.00067000",
     "t" : 1312486485,
     "M" : true,
     "E" : 1648828827635,
     "p" : "46566.99000000",
     "e" : "trade",
     "T" : 1648828827634,
     "s" : "BTCUSDT",
     "b" : 10041835161,
     "a" : 10041835278,
     "m" : true
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "T" : 1648828827634,
     "p" : "46566.99000000",
     "M" : true,
     "b" : 10041835161,
     "E" : 1648828827635,
     "e" : "trade",
     "t" : 1312486485,
     "q" : "0.00067000",
     "s" : "BTCUSDT",
     "a" : 10041835278,
     "m" : true
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "q" : "0.00067000",
     "t" : 1312486485,
     "M" : true,
     "E" : 1648828827635,
     "p" : "46566.99000000",
     "e" : "trade",
     "T" : 1648828827634,
     "s" : "BTCUSDT",
     "b" : 10041835161,
     "a" : 10041835278,
     "m" : true
     }
     2022-04-02 00:00:27:TradeWebSocket.didReceiveMessageWith:{
     "q" : "0.00067000",
     "t" : 1312486485,
     "M" : true,
     "E" : 1648828827635,
     "p" : "46566.99000000",
     "e" : "trade",
     "T" : 1648828827634,
     "s" : "BTCUSDT",
     "b" : 10041835161,
     "a" : 10041835278,
     "m" : true
     }
     */
}
