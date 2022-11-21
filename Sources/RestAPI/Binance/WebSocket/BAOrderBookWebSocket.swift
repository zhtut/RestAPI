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
    
    open var symbol = ""
    open var orderBook = BAOrderBook()
    open var orderBookChangedHandler: ((_ orderBook: BAOrderBook) -> Void)?
    
    public convenience init(symbol: String) {
        self.init()
        self.symbol = symbol
        orderBook.instId = symbol
        self.open()
    }
    
    open override var urlStr: String {
        let str = "\(APIKeyConfig.default.BA_Websocket_URL_Str)/\(symbol.lowercased())@depth@100ms"
        return str
    }

    open override func webSocketDidReceive(message: [String: Any]) {
        super.webSocketDidReceive(message: message)
        Task {
            let result = await orderBook.update(message: message)
            if result {
                orderBookChangedHandler?(orderBook)
            }
        }
    }
}
