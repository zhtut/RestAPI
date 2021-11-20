//
//  File.swift
//  
//
//  Created by zhtg on 2021/9/13.
//

import Foundation

open class OKHistoryTrade: NSObject, Codable {
    open var instId: String? /// ": "BTC-USDT",
    open var tradeId: String? /// ": "130639474",
    open var px: String? /// ": "42219.9",
    open var sz: String? /// ": "0.12060306",
    open var side: String? /// ": "buy",
    open var ts: String? /// ": "1630048897897"
    
    open override var description: String {
        if let ts = ts,
           let instId = instId,
           let side = side,
           let px = px,
           let sz = sz {
            return "\(ts) \(instId) \(side) \(px) \(sz)"
        }
        return super.description
    }
}
