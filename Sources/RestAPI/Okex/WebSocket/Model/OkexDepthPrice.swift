//
//  File.swift
//  
//
//  Created by shutut on 2021/9/12.
//

import Foundation

/// 深度价格
open class OkexDepthPrice: NSObject {
    /// 价格
    open var px: Double = 0
    /// 交易量
    open var sz: Double = 0
    /// 强平订单
    open var fSz: Double = 0
    /// 订单数量
    open var oSz: Double = 0
    
    open override var description: String {
        return "\(px) \(sz)"
    }
    
    open class func priceWith(_ array: [String]) -> OkexDepthPrice? {
        if array.count < 4 {
            return nil
        }
        let  model = OkexDepthPrice()
        model.px = array[0].doubleValue ?? 0
        model.sz = array[1].doubleValue ?? 0
        model.fSz = array[2].doubleValue ?? 0
        model.oSz = array[3].doubleValue ?? 0
        return model
    }
}
