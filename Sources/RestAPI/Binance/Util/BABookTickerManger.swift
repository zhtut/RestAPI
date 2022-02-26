//
//  BABookTickerManger.swift
//  
//
//  Created by zhtg on 2022/2/26.
//

import Foundation

open class BABookTickerManger {

    public static let shared = BABookTickerManger()
    
    open var instId: String?
    open var centerPrice: Decimal?
    open var bookTicker: BABookTicker?
    
    public static let bookTickerChangedNotification = Notification.Name("BABookTickerChangedNotification")
    
    open func subcribeDepth() {
        BAMarketWebSocket.shared.subBookTicker(symbol: instId!)
        let _ = NotificationCenter.default.addObserver(forName: BAMarketWebSocket.bookTickerDidChangeNotification, object: nil, queue: nil) { noti in
            self.bookTickerDidChange(noti: noti)
        }
    }
    
    open func bookTickerDidChange(noti: Notification) {
        if let bookTicker = noti.object as? BABookTicker {
            centerPrice = bookTicker.center
            self.bookTicker = bookTicker
            NotificationCenter.default.post(name: BABookTickerManger.bookTickerChangedNotification, object: bookTicker)
        }
    }
}
