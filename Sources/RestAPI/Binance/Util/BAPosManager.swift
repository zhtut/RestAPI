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
    
    open var lever: Int = 1
    
    open var initalBusd: Decimal = 0
    
    open var instrument: Instrument {
        return BAAppSetup.shared.instrument
    }
    
    public init() {
        let _ = NotificationCenter.default.addObserver(forName: BAUserWebSocket.websocketDidReadyNotification, object: nil, queue: nil) { noti in
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
        if initalBusd == 0 {
            initalBusd = busd
        }
        configLever()
    }
    
    open func positionChanged(noti: Notification) {
        let busd = BAUserWebSocket.shared.busdBal ?? 0.0
        log("--------------账户信息变化：初始busd:\(self.initalBusd), 当前BUSD:\(busd)，已赚\(busd - initalBusd)")
        if let position = BAUserWebSocket.shared.positions?.first {
            log("position数量变化:\(position.positionAmt)，持仓价格：\(position.entryPrice)，canOpen:\(canOpenSz), total: \(total)")
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
        if let busd = BAUserWebSocket.shared.busdBal,
           let currPx = BABookTickerManger.shared.centerPrice {
            let total = busd * lever.decimalValue / currPx
            return total
        }
        return 0
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
        return total - dabs(posSz) - orderPosSz
    }
    
    open var baseSz: Decimal {
        var minSz = instrument.minSz.decimalValue ?? 0.0
        let lotSz = instrument.lotSz.decimalValue ?? 0.0
        let currPx = BABookTickerManger.shared.centerPrice ?? 0.0
        while minSz * currPx < 5 {
            minSz += lotSz
        }
        return minSz
    }
}
