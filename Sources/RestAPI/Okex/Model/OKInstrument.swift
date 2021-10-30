//
//  OKInstruments.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/15.
//

import Foundation

public struct OKInstrument: Codable {
    public var instType    : String? ///<     产品类型
    public var instId    : String? ///<     产品ID，如 BTC-USD-SWAP
    public var category    : String? ///<     手续费档位，每个交易产品属于哪个档位手续费
    public var uly    : String? ///<     合约标的指数，如 BTC-USD ，仅适用于交割/永续/期权
    public var baseCcy    : String? ///<     交易货币币种，如 BTC-USDT 中BTC ，仅适用于币币
    public var quoteCcy    : String? ///<     计价货币币种，如 BTC-USDT 中 USDT ，仅适用于币币
    public var settleCcy    : String? ///<     盈亏结算和保证金币种，如 BTC ，仅适用于 交割/永续/期权
    public var ctVal    : String? ///<     合约面值
    public var ctMult    : String? ///<     合约乘数
    public var ctValCcy    : String? ///<     合约面值计价币种
    public var optType    : String? ///<     期权类型，C：看涨期权 P：看跌期权 ，仅适用于期权
    public var stk    : String? ///<     行权价格， 仅适用于期权
    public var listTime    : String? ///<     上线日期， 仅适用于 交割/永续/期权
    public var expTime    : String? ///<     交割日期， 仅适用于 交割/期权
    public var lever    : String? ///<     杠杆倍数， 不适用于币币
    public var tickSz    : String? ///<     下单价格精度，如 0.0001
    public var lotSz    : String? ///<     下单数量精度，如 1：BTC-USDT-200925 0.001：BTC-USDT
    public var minSz    : String? ///<     最小下单数量
    public var ctType    : String? ///<     合约类型，linear：正向合约 inverse：反向合约
    public var alias    : String? ///<     合约日期别名
    // this_week：本周
    // next_week：次周
    // quarter：季度
    // next_quarter：次季度
    
    // 仅适用于交割
    public var state    : String? ///<     产品状态
    // live：交易中
    // suspend：暂停中
    // expired：已过期
    // prepublic：预上线
    
    public static func instrumentWith(instId: String, completion: @escaping (OKInstrument?, String?) -> Void) {
        let path = "/api/v5/public/instruments"
        let params = ["instId": instId, "instType": "SWAP"]
        OKRestAPI.sendRequestWith(path: path,
                                    params: params,
                                    method: .GET,
                                    dataClass: OKInstrument.self) { response in
            if response.responseSucceed,
               let array = response.data as? [OKInstrument],
               let ins = array.first {
                completion(ins, nil)
                return
            }
            completion(nil, response.errorMsg)
        }
    }
}
