//
//  File.swift
//  
//
//  Created by shutut on 2021/9/8.
//

import Foundation
import SSCommon

/// 币种信息
public struct Instrument: Codable {
    
    public init() {
        
    }
    
    /// symbol
    public var instId: String = ""
    /// 交易货币币种，如 BTC-USDT 中BTC ，仅适用于币币
    public var baseCcy: String = ""
    /// 计价货币币种，如 BTC-USDT 中 USDT ，仅适用于币币
    public var quoteCcy: String = ""
    /// 下单价格精度，如 BTCUSDT的下单精度是0.01，就是小数点后两位
    public var tickSz: String = ""
    /// 下单数量精度，如 BTCUSDT的下单数量必须大于 0.00001，并且累加也是0.00001往上加，如0.00002
    public var lotSz: String = ""
    /// 下单最小值
    public var minSz: String = ""
    
    public var description: String {
        let jsonString = self.transformToJson()
        return "\(jsonString ?? [:])"
    }
    
    public func precisionPrice(_ price: Decimal) -> Decimal {
        return price.precisionStringWith(precision: tickSz).decimalValue ?? 0
    }
    
    public func precisionSize(_ size: Decimal) -> Decimal {
        return size.precisionStringWith(precision: lotSz).decimalValue ?? 0
    }
}
