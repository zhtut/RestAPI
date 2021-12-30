//
//  File.swift
//  
//
//  Created by shutut on 2021/12/30.
//

import Foundation

open class BADepthBook {
    
    var symbol: String?
    
    public convenience init(symbol: String) {
        self.init()
        self.symbol = symbol
    }
    
    open func start() {
        if let symbol = symbol {
            BAMarketWebSocket.shared.subscribe(params: ["\(symbol)@depth@100ms"])
        }
    }
}
