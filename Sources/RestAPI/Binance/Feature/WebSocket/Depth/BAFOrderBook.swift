//
//  File.swift
//  
//
//  Created by shutut on 2021/12/30.
//

import Foundation
import SSLog

open class BAFOrderBook {
    
    open var instId = ""
    
    open var bids = [BAFOrderBookPrice]()
    open var asks = [BAFOrderBookPrice]()
    
    open var U: Int = 0
    open var E: Int = 0
    open var T: Int = 0
    
    open var u: Int = 0
    open var pu: Int = 0
    
    open var isRefreshing = false
    
    open func refreshOrderBook() async {
        isRefreshing = true
        let path = "GET /fapi/v1/depth"
        let params = ["symbol": instId, "limit": 100] as [String: Any]
        let response = await BARestAPI.sendRequestWith(path: path, params: params)
        if response.responseSucceed {
            if let message = response.data as? [String: Any] {
                if let a = message["asks"] as? [[String]],
                   let b = message["bids"] as? [[String]] {
                    self.asks.removeAll()
                    self.bids.removeAll()
                    self.updateAsks(a: a)
                    self.updateBids(b: b)
                }
                self.u = message.intFor("lastUpdateId") ?? 0
                self.isRefreshing = false
            }
        }
    }
    
    open func update(message: [String: Any]) async -> Bool {
        if self.isRefreshing {
            return false
        }
        
        let pu = message.intFor("pu") ?? 0
        if pu != u {
            await refreshOrderBook()
            return false
        }
        
        if let a = message["a"] as? [[String]],
           let b = message["b"] as? [[String]] {
            updateAsks(a: a)
            updateBids(b: b)
        }
        if let s = message.stringFor("s") {
            instId = s
        }
        
        U = message.intFor("U") ?? 0
        E = message.intFor("E") ?? 0
        T = message.intFor("T") ?? 0
        u = message.intFor("u") ?? 0
        
        return true
    }
    
    open func updateAsks(a: [[String]]) {
        for arr in a {
            let ob = BAFOrderBookPrice(array: arr)
            var newAsks = asks.filter { orderBook in
                return ob.p != orderBook.p
            }
            if ob.v > 0 {
                newAsks.append(ob)
            }
            asks = newAsks
            asks.sort {
                $0.p < $1.p
            }
        }
    }
    
    open func updateBids(b: [[String]]) {
        for arr in b {
            let ob = BAFOrderBookPrice(array: arr)
            var newBids = bids.filter { orderBook in
                return ob.p != orderBook.p
            }
            if ob.v > 0 {
                newBids.append(ob)
            }
            bids = newBids
            bids.sort {
                $0.p > $1.p
            }
        }
    }
    
    open func logOrderBook() {
        logPrice(arr: asks, index: 4)
        logPrice(arr: asks, index: 3)
        logPrice(arr: asks, index: 2)
        logPrice(arr: asks, index: 1)
        logPrice(arr: asks, index: 0)
        log("------")
        logPrice(arr: bids, index: 0)
        logPrice(arr: bids, index: 1)
        logPrice(arr: bids, index: 2)
        logPrice(arr: bids, index: 3)
        logPrice(arr: bids, index: 4)
    }
    
    open func logPrice(arr: [BAFOrderBookPrice], index: Int) {
        if arr.count > index {
            let price = arr[index]
            log("\(price.p) \(price.v)")
        }
    }
}

/// 盘口价格
open class BAFOrderBookPrice {
    /// 价格
    open var p: Decimal = 0
    /// 数量
    open var v: Decimal = 0
    
    public convenience init(array: [String]) {
        self.init()
        if let p = Decimal(string: array[0]) {
            self.p = p
        }
        if let v = Decimal(string: array[1]) {
            self.v = v
        }
    }
}
