//
//  BAOrderBookManager.swift
//  
//
//  Created by zhtg on 2022/3/3.
//

import Foundation

open class BAOrderBookManager {
    
    public static let shared = BAOrderBookManager()
    
    open var instId: String?
    
    public static let orderBookChangedNotification = Notification.Name("BAOrderBookChangedNotification")
    
    open func subcribeOrderBook() {
        guard let instId = instId else {
            return
        }
        BAMarketWebSocket.shared.subOrderBook(symbol: instId)
//        let _ = NotificationCenter.default.addObserver(forName: BAMarketWebSocket.bookTickerDidChangeNotification, object: nil, queue: nil) { noti in
//            self.bookTickerDidChange(noti: noti)
//        }
    }
    
//    open func bookTickerDidChange(noti: Notification) {
//        if let bookTicker = noti.object as? BABookTicker {
//            centerPrice = bookTicker.center
//            self.bookTicker = bookTicker
//            NotificationCenter.default.post(name: BABookTickerManger.bookTickerChangedNotification, object: bookTicker)
//        }
//    }

}
