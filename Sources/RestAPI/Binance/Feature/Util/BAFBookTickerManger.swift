//
//  BAFBookTickerManger.swift
//  
//
//  Created by zhtg on 2022/2/26.
//

import Foundation

open class BAFBookTickerManger {

    public static let shared = BAFBookTickerManger()
    
    open var instId: String?
    open var centerPrice: Decimal?
    open var bookTicker: BAFBookTicker?
    
    open var bookTickerWebSocket: BAFBookTickerWebSocket?
    
    public static let bookTickerChangedNotification = Notification.Name("BAFBookTickerChangedNotification")
    
    open func subcribeDepth() {
        guard let instId = instId else {
            return
        }
        
        bookTickerWebSocket = BAFBookTickerWebSocket(symbol: instId)
        let _ = NotificationCenter.default.addObserver(forName: BAFBookTickerWebSocket.bookTickerDidChangeNotification, object: nil, queue: nil) { noti in
            self.bookTickerDidChange(noti: noti)
        }
    }
    
    open func bookTickerDidChange(noti: Notification) {
        if let bookTicker = noti.object as? BAFBookTicker {
            centerPrice = bookTicker.center
            self.bookTicker = bookTicker
            NotificationCenter.default.post(name: BAFBookTickerManger.bookTickerChangedNotification, object: bookTicker)
        }
    }
}
