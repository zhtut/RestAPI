//
//  File.swift
//  
//
//  Created by shutut on 2021/11/27.
//

import Foundation
import SSLog
import SSCommon

open class BAPosManager {
    
    public static let shared = BAPosManager()
    
    open var bookTickerManger: BABookTickerManger?
    open var instrument: Instrument?
    
    open var lever: Int = 1
    
    public init() {
        let _ = NotificationCenter.default.addObserver(forName: BAUserWebSocket.accountRefreshedNotification, object: nil, queue: nil) { noti in
            self.positionRefreshed(noti: noti)
        }
        let _ = NotificationCenter.default.addObserver(forName: BAUserWebSocket.accountChangedNotification, object: nil, queue: nil) { noti in
            self.positionChanged(noti: noti)
        }
    }
    
    open func positionRefreshed(noti: Notification) {
        let busd = BAUserWebSocket.shared.busdBal ?? 0.0
        log("账户拉取成功：当前BUSD:\(busd)")
        if let position = BAUserWebSocket.shared.positions?.first {
            log("position数量:\(position.positionAmt)")
        }
        configLever()
    }
    
    open func positionChanged(noti: Notification) {
        let busd = BAUserWebSocket.shared.busdBal ?? 0.0
        log("账户信息变化：当前BUSD:\(busd)")
        if let position = BAUserWebSocket.shared.positions?.first {
            log("position数量:\(position.positionAmt)")
        }
        configLever()
    }
    
    open func configLever() {
        if let positions = BAUserWebSocket.shared.positions,
           let first = positions.first,
           let lever = first.leverage.intValue {
            self.lever = lever
        }
    }
    
    open var total: Decimal {
        return dabs(posSz) + canOpenSz + orderPosSz
    }
    
    /// 冻结在订单中的合约张数
    open var orderPosSz: Decimal {
        if let orders = BAUserWebSocket.shared.orders,
            orders.count > 0 {
            var count = Decimal(0.0)
            for or in orders {
                if let pos = or.origQty?.decimalValue {
                    count += dabs(pos)
                }
            }
            return count
        }
        return 0
    }
    
    /// 持仓总张数
    open var posSz: Decimal {
        if let positions = BAUserWebSocket.shared.positions {
            var count = Decimal(0.0)
            for po in positions {
                if let pos = po.positionAmt.decimalValue {
                    count += pos
                }
            }
            return count
        }
        return 0
    }
    
    /// 持仓成本价格
    open var posAvgPrice: Decimal? {
        if let position = BAUserWebSocket.shared.positions?.first {
            return position.entryPrice.decimalValue
        }
        return nil
    }
    
    /// 持仓多方向合约张数
    open var longPosSz: Decimal {
        if let positions = BAUserWebSocket.shared.positions {
            var count = Decimal(0.0)
            for po in positions {
                if let pos = po.positionAmt.decimalValue,
                   pos > 0 {
                    count += abs(pos)
                }
            }
            if count < baseSz {
                return 0.0
            }
            return count
        }
        return 0
    }
    
    /// 持仓空方向合约张数
    open var shortPosSz: Decimal {
        if let positions = BAUserWebSocket.shared.positions {
            var count = Decimal(0.0)
            for po in positions {
                if let pos = po.positionAmt.decimalValue,
                   pos < 0 {
                    count += abs(pos)
                }
            }
            if count < baseSz {
                return 0.0
            }
            return count
        }
        return 0
    }
    
    /// 可开张数
    open var canOpenSz: Decimal {
        if let busd = BAUserWebSocket.shared.busdBal,
           let currPx = bookTickerManger?.centerPrice {
            let canOpen = busd * lever.decimalValue / currPx
            return canOpen - dabs(posSz) - orderPosSz
        }
        return 0
    }
    
    open var baseSz: Decimal {
        let lotSz = instrument?.lotSz.decimalValue ?? 0.0
        return lotSz * 3.0
    }
}
