//
//  BAUserWebSocket.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/23.
//

import Foundation
import SSCommon

class BAUserWebSocket: BAWebSocket {
    
    static let shared = OkexMarketWebSocket()
    
    override var urlStr: String {
        "wss://stream.binance.com:9443"
    }
    
    /// k线图变化的通知
//    static let candleDidChangeNotification = Notification.Name("SCCandleDidChangeNotification")
    
}
