//
//  BACandleWebSocket.swift
//  
//
//  Created by zhtg on 2022/5/7.
//

import Foundation
import SSCommon
import SSLog

open class BAOrderBookWebSocket: BAWebSocket {
    
    var symbol = ""
    var orderBook: BAOrderBook?
    
    public convenience init(symbol: String) {
        self.init()
        self.symbol = symbol
        orderBook = BAOrderBook()
        orderBook?.instId = symbol
        self.open()
    }
    
    open override var urlStr: String {
        let str = "\(APIKeyConfig.default.BA_Websocket_URL_Str)/\(symbol.lowercased())@depth@100ms"
        return str
    }
    
    /// OrderBook变化的通知
    public static let orderBookDidChangeNotification = Notification.Name("BAOrderBookDidChangeNotification")

    open override func webSocketDidReceive(message: [String: Any]) {
        super.webSocketDidReceive(message: message)
        orderBook?.update(message: message)
        NotificationCenter.default.post(name: BAOrderBookWebSocket.orderBookDidChangeNotification, object: orderBook)
    }
}
