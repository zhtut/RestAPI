//
//  File.swift
//  
//
//  Created by shutut on 2021/9/12.
//

import Foundation

public extension Array where Element == OKDepthPrice {
    mutating func setupWith(array: [[String]]) {
        removeAll()
        for arr in array {
            if let price = OKDepthPrice.priceWith(arr) {
                append(price)
            }
        }
    }
    
    mutating func updateWith(array: [[String]]) {
        for arr in array {
            if let newPrice = OKDepthPrice.priceWith(arr) {
                updateWith(newPrice: newPrice)
            }
        }
    }
    
    mutating func updateWith(newPrice: OKDepthPrice) {
        for (index, price) in self.enumerated() {
            /// 价格一样，先移除
            if price.px == newPrice.px {
                remove(at: index)
                break
            }
        }
        /// 新价格有数量，才加入到数组中，待后面再排下序
        if let sz = newPrice.sz.doubleValue,
           sz > 0 {
            append(newPrice)
        }
    }
}

open class OKDepthData: NSObject {
    open var bids = [OKDepthPrice]()
    open var asks = [OKDepthPrice]()
    
    open var hasData: Bool {
        if bids.count > 0 && asks.count > 0 {
            return true
        }
        return false
    }
    
    open var center: Double? {
        if hasData {
            if let ask = asks.first,
               let askPx = ask.px.doubleValue,
               let bid = bids.first,
               let bidPx = bid.px.doubleValue {
                let center = (askPx + bidPx) * 0.5
                return center
            }
        }
        return nil
    }
    
    public static let didChangeNotification = Notification.Name("OKDidChangeNotification")
    
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
            
            sort()
        }
    }
    
    open func updateWith(data: [[String: Any]]) {
        if let dic = data.first {
            if let datas = dic["asks"] as? [[String]] {
                asks.updateWith(array: datas)
            }
            
            if let datas = dic["bids"] as? [[String]] {
                bids.updateWith(array: datas)
            }
            
            sort()
            
            let maxLength = 50
            if asks.count > maxLength {
                asks = asks.suffix(maxLength)
            }
            if bids.count > maxLength {
                bids = bids.suffix(maxLength)
            }
            
            NotificationCenter.default.post(name: OKDepthData.didChangeNotification, object: self)
        }
    }
    
    func sort() {
        asks.sort { p1, p2 in
            p1.px < p2.px
        }
        bids.sort { p1, p2 in
            p1.px > p2.px
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
