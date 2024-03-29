//
//  File.swift
//  
//
//  Created by shutut on 2021/11/27.
//

import Foundation
import SSLog
import SSCommon

open class BAFPosManager {
    
    public static let shared = BAFPosManager()
    
    open var lever: Int = 1
    
    open var initalBusd: Decimal = 0
    
    open var instrument: Instrument {
        return BAFAppSetup.shared.instrument
    }
    
    public init() {
        let _ = NotificationCenter.default.addObserver(forName: BAFAccountWebSocket.websocketDidReadyNotification, object: nil, queue: nil) { noti in
            self.positionRefreshed(noti: noti)
        }
        let _ = NotificationCenter.default.addObserver(forName: BAFAccountWebSocket.accountChangedNotification, object: nil, queue: nil) { noti in
            self.positionChanged(noti: noti)
        }
    }
    
    open func positionRefreshed(noti: Notification) {
        let busd = BAFAccountWebSocket.shared.busdBal ?? 0.0
        log("账户拉取成功：当前BUSD:\(busd)")
        if let position = BAFAccountWebSocket.shared.positions?.first {
            log("position数量:\(position.positionAmt)")
        }
        if initalBusd == 0 {
            initalBusd = busd
        }
        refreshLever()
    }
    
    open func positionChanged(noti: Notification) {
        let busd = BAFAccountWebSocket.shared.busdBal ?? 0.0
        log("--------------账户信息变化：初始busd:\(self.initalBusd), 当前BUSD:\(busd)，已赚\(busd - initalBusd)")
        if let position = BAFAccountWebSocket.shared.positions?.first {
            log("position数量变化:\(position.positionAmt)，持仓价格：\(position.entryPrice)，canOpen:\(canOpenSz), total: \(total)")
        }
        refreshLever()
    }
    
    open func refreshLever() {
        if let positions = BAFAccountWebSocket.shared.positions,
           let first = positions.first,
           let lever = first.leverage.intValue {
            self.lever = lever
        }
    }
    
    
    /// 总张数，包括
    open var total: Decimal {
        if let busd = BAFAccountWebSocket.shared.busdBal,
           let currPx = BAFBookTickerManger.shared.centerPrice {
            let total = busd * lever.decimalValue / currPx
            return total
        }
        return 0
    }
    
    /// 冻结在订单中的合约张数
    open var orderPosSz: Decimal {
        if let orders = BAFAccountWebSocket.shared.orders,
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
        if let positions = BAFAccountWebSocket.shared.positions {
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
        if let position = BAFAccountWebSocket.shared.positions?.first {
            return position.entryPrice.decimalValue
        }
        return nil
    }
    
    /// 持仓多方向合约张数
    open var longPosSz: Decimal {
        if let positions = BAFAccountWebSocket.shared.positions {
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
        if let positions = BAFAccountWebSocket.shared.positions {
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
        let canopen = total - dabs(posSz) - orderPosSz
        let temp = canopen.precisionStringWith(precision: BAFAppSetup.shared.instrument.lotSz)
        return temp.decimalValue!
    }
    
    open var baseSz: Decimal {
        var minSz = instrument.minSz.decimalValue ?? 0.0
        let lotSz = instrument.lotSz.decimalValue ?? 0.0
        let currPx = BAFBookTickerManger.shared.centerPrice ?? 0.0
        while minSz * currPx < 5 {
            minSz += lotSz
        }
        return minSz
    }
}
