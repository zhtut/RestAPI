//
//  BAFCandleWebSocket.swift
//  
//
//  Created by zhtg on 2022/5/7.
//

import Foundation
import SSCommon
import SSLog

open class BAFCandleWebSocket: BAWebSocket {
    
    var symbol = ""
    /// 1m
    /// 3m
    /// 5m
    /// 15m
    /// 30m
    /// 1h
    /// 2h
    /// 4h
    /// 6h
    /// 8h
    /// 12h
    /// 1d
    /// 3d
    /// 1w
    /// 1M
    var interval = ""
    
    public convenience init(symbol: String, period: String) {
        self.init()
        self.symbol = symbol
        self.interval = period
        self.open()
    }
    
    open override var urlStr: String {
        let str = "\(APIKeyConfig.default.BA_Websocket_URL_Str)/\(symbol.lowercased())@kline_\(interval)"
        return str
    }
    
    /// k线图变化的通知
    public static let candleDidChangeNotification = Notification.Name("BACandleDidChangeNotification")

    open override func webSocketDidReceive(message: [String: Any]) {
        super.webSocketDidReceive(message: message)
        if let tick = message["k"] as? [String: Any] {
            let candle = tick.transformToModel(BAFCandle.self)
            NotificationCenter.default.post(name: BAFCandleWebSocket.candleDidChangeNotification, object: candle)
        }
    }
}
