//
//  OkexPosition.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/1.
//

import Foundation
import SSCommon

public struct OkexPosition: Codable {
    
    public var instType: String? ///< String?    产品类型
    public var mgnMode: String? ///< String?    保证金模式 cross：全仓 isolated：逐仓
    public var posId: String? ///< String?    持仓ID
    public var posSide: String? ///< String?    持仓方向 long：双向持仓多头 short：双向持仓空头net：单向持仓（交割/永续/期权：pos为正代表多头，pos为负代表空头。币币杠杆：posCcy为交易货币时，代表多头； y为计价货币时，代表空头。）
    public var pos: String? ///< String?    持仓数量
    public var posCcy: String? ///< String?    仓位资产币种，仅适用于币币杠杆仓位
    public var availPos: String? ///< String?    可平仓数量，适用于 币币杠杆,交割/永续（开平仓模式），期权（交易账户及保证金账户逐仓）。
    public var avgPx: String? ///< String?    开仓平均价
    public var upl: String? ///< String?    未实现收益
    public var uplRatio: String? ///< String?    未实现收益率
    public var instId: String? ///< String?    产品ID，如 BTC-USD-180216
    public var lever: String? ///< String?    杠杆倍数，不适用于期权
    public var liqPx: String? ///< String?    预估强平价 不适用于跨币种保证金模式下交割/永续的全仓 不适用于期权
    public var imr: String? ///< String?    初始保证金，仅适用于全仓
    public var margin: String? ///< String?    保证金余额，可增减，仅适用于逐仓
    public var mgnRatio: String? ///< String?    保证金率
    public var mmr: String? ///< String?    维持保证金
    public var liab: String? ///< String?    负债额，仅适用于币币杠杆
    public var liabCcy: String? ///< String?    负债币种，仅适用于币币杠杆
    public var interest: String? ///< String?    利息，已经生成的未扣利息
    public var tradeId: String? ///< String?    最新成交ID
    public var optVal: String? ///< String?    期权市值，仅适用于期权
    public var adl: String? ///< String?    信号区 分为5档，从1到5，数字越小代表adl强度越弱
    public var ccy: String? ///< String?    占用保证金的币种
    public var last: String? ///< String?    最新成交价
    public var deltaBS: String? ///< String?    美金本位持仓仓位delta，仅适用于期权
    public var deltaPA: String? ///< String?    币本位持仓仓位delta，仅适用于期权
    public var gammaBS: String? ///< String?    美金本位持仓仓位gamma，仅适用于期权
    public var gammaPA: String? ///< String?    币本位持仓仓位gamma，仅适用于期权
    public var thetaBS: String? ///< String?    美金本位持仓仓位theta，仅适用于期权
    public var thetaPA: String? ///< String?    币本位持仓仓位theta，仅适用于期权
    public var vegaBS: String? ///< String?    美金本位持仓仓位vega，仅适用于期权
    public var vegaPA: String? ///< String?    币本位持仓仓位vega，仅适用于期权
    public var cTime: String? ///< String?    持仓创建时间，Unix时间戳的毫秒数格式，如 1597026383085
    public var uTime: String? ///< String?    最近一次持仓更新时间，Unix时间戳的毫秒数格式，如 1597026383085

    public var positionDesc: String {
        let str = "持仓\(lever!)倍做\(posSide! == "long" ? "多" : "空")\n\(pos!)张"
        return str
    }
    
    public func closePositionWith(completion: @escaping (Bool, String?) -> Void) {
        let path = "/api/v5/trade/order";
        let params = closePositionParams()
        print("下单进行清仓操作，params:\(params)")
        OkexRestAPI.sendRequestWith(path: path, params: params, method: .POST) { response in
            if response.responseSucceed {
                completion(true, nil)
            } else {
                completion(false, response.errorMsg)
            }
        }
    }
    
    public func closePositionParams() -> [String: Any] {
        var params = ["tdMode": "cross", "ccy": "USDT", "ordType": "market"]
        params["instId"] = instId
        if let posSide = self.posSide {
            if posSide == "long" {
                params["side"] = "sell"
            } else {
                params["side"] = "buy"
            }
        }
        params["posSide"] = posSide
        let sz = fabs(pos?.doubleValue ?? 0.0)
        params["sz"] = "\(sz)"
        return params;
    }
    
    public static func closePositions(positions: [OkexPosition], completion: @escaping (Bool, String?) -> Void) {
        
        let path = "/api/v5/trade/batch-orders";
        var array = [[String: Any]]()
        for position in positions {
            let dic = position.closePositionParams()
            array.append(dic)
        }
        OkexRestAPI.sendRequestWith(path: path, params: array, method: .POST) { response in
            if response.responseSucceed {
                completion(true, nil)
            } else {
                completion(false, response.errorMsg!)
            }
        }
    }
}
