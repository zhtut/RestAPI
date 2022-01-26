//
//  File.swift
//  
//
//  Created by shutut on 2021/12/30.
//

import Foundation

open class BADepthBook {
    
    open var symbol: String?
    
    public convenience init(_ symbol: String? = nil) {
        self.init()
        self.symbol = symbol
    }
    
    open func start() {
        if let symbol = symbol {
            let streamName = "\(symbol.lowercased())@bookTicker"
            BAMarketWebSocket.shared.subscribe(params: [streamName])
        }
    }
}
