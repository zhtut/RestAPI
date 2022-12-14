//
//  BAFCandleWebSocket.swift
//  
//
//  Created by zhtg on 2022/5/7.
//

import Foundation
import SSCommon
import SSLog

open class BAFBookTickerWebSocket: BAWebSocket {
    
    var symbol = ""
    
    public convenience init(symbol: String) {
        self.init()
        self.symbol = symbol
        self.open()
    }
    
    open override var urlStr: String {
        let str = "\(APIKeyConfig.default.BA_Websocket_URL_Str)/\(symbol.lowercased())@bookTicker"
        return str
    }
    
    /// 最新买卖价变化的通知
    public static let bookTickerDidChangeNotification = Notification.Name("BAFBookTickerDidChangeNotification")

    open override func webSocketDidReceive(message: [String: Any]) {
        super.webSocketDidReceive(message: message)
        /*
         {"stream":"ethbusd@bookTicker","data":{"e":"bookTicker","u":1154786566700,"s":"ETHBUSD","b":"2450.03","B":"2.346","a":"2450.04","A":"1.626","T":1643162839528,"E":1643162839533}}
         */
        if let bookTicker = message.transformToModel(BAFBookTicker.self) {
            NotificationCenter.default.post(name: BAFBookTickerWebSocket.bookTickerDidChangeNotification, object: bookTicker)
        }
    }
}
