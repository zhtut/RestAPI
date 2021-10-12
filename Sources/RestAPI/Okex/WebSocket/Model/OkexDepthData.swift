//
//  File.swift
//  
//
//  Created by shutut on 2021/9/12.
//

import Foundation

public extension Array where Element == OkexDepthPrice {
    mutating func setupWith(array: [[String]]) {
        removeAll()
        for arr in array {
            if let price = OkexDepthPrice.priceWith(arr) {
                append(price)
            }
        }
    }
    
    mutating func updateWith(array: [[String]]) {
        for arr in array {
            if let newPrice = OkexDepthPrice.priceWith(arr) {
                updateWith(newPrice: newPrice)
            }
        }
    }
    
    mutating func updateWith(newPrice: OkexDepthPrice) {
        for (index, price) in self.enumerated() {
            /// 价格一样，先移除
            if price.px == newPrice.px {
                remove(at: index)
                break
            }
        }
        /// 新价格有数量，才加入到数组中，待后面再排下序
        if newPrice.sz.stringValue != "0" {
            append(newPrice)
        }
    }
}

open class OkexDepthData: NSObject {
    open var bids = [OkexDepthPrice]()
    open var asks = [OkexDepthPrice]()
    
    open var hasData: Bool {
        if bids.count > 0 && asks.count > 0 {
            return true
        }
        return false
    }
    
    open var center: Double? {
        if hasData {
            let ask = asks.first
            let bid = bids.first
            let center = (ask!.px + bid!.px) * 0.5
            return center
        }
        return nil
    }
    
    public static let didChangeNotification = Notification.Name("OkexDidChangeNotification")
    
    open func setupWith(data: [[String: Any]]) {
        bids.removeAll()
        asks.removeAll()
        if let dic = data.first {
            if let datas = dic["asks"] as? [[String]] {
                asks.setupWith(array: datas)
            }
            
            if let datas = dic["bids"] as? [[String]] {
                bids.setupWith(array: datas)
            }
        }
    }
    
    open func updateWith(data: [[String: Any]]) {
        if let dic = data.first {
            if let datas = dic["asks"] as? [[String]] {
                asks.updateWith(array: datas)
                asks.sort { p1, p2 in
                    p1.px < p2.px
                }
            }
            
            if let datas = dic["bids"] as? [[String]] {
                bids.updateWith(array: datas)
                bids.sort { p1, p2 in
                    p1.px > p2.px
                }
            }
            
            NotificationCenter.default.post(name: OkexDepthData.didChangeNotification, object: self)
        }
    }
    
    open override var description: String {
        guard asks.count > 5 else {
            return super.description
        }
        guard bids.count > 5 else {
            return super.description
        }
        var message = "\n"
        var values = [String]()
        for index in (0..<5) {
            let price = asks[index]
            values.append(price.description)
        }
        values = values.reversed()
        message.append(values.joined(separator: "\n"))
        message.append("\n------\n")
        values.removeAll()
        for index in (0..<5) {
            let price = bids[index]
            values.append(price.description)
        }
        message.append(values.joined(separator: "\n"))
        return message
    }
}
