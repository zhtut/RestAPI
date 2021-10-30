//
//  BAInstrument.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/23.
//

import Foundation

open class BAInstrument: NSObject {
    open var symbol: String? ///": "ETHBTC",
    open var status: String? ///": "TRADING",
    open var baseAsset: String? ///": "ETH",
    open var baseAssetPrecision: Int? ///": 8,
    open var quoteAsset: String? ///": "BTC",
    open var quotePrecision: Int? ///": 8,
    open var quoteAssetPrecision: Int? ///": 8,
    open var orderTypes: [String]? ///": [
//    LIMIT",
//    LIMIT_MAKER",
//    MARKET",
//    STOP_LOSS",
//    STOP_LOSS_LIMIT",
//    TAKE_PROFIT",
//    TAKE_PROFIT_LIMIT"
//    ],
    open var icebergAllowed: Bool? ///": true,
    open var ocoAllowed: Bool? ///": true,
    open var isSpotTradingAllowed: Bool? ///": true,
    open var isMarginTradingAllowed: Bool? ///": true,
    open var filters: [[String: Any]]?  ///": [
    //这些在"过滤器"部分中定义
    //所有限制都是可选的
//    ],
    open var permissions: [String]? /// ": [
//    "SPOT",
//    "MARGIN"
//    ]
//    }
    
    open class func modelWith(dic: [String: Any]) -> BAInstrument {
        let model = BAInstrument()
        model.symbol = dic.stringFor("symbol")
        model.status = dic.stringFor("status")
        model.baseAsset = dic.stringFor("baseAsset")
        model.baseAssetPrecision = dic.intFor("baseAssetPrecision")
        model.quoteAsset = dic.stringFor("quoteAsset")
        model.quotePrecision = dic.intFor("quotePrecision")
        model.quoteAssetPrecision = dic.intFor("quoteAssetPrecision")
        model.orderTypes = dic.arrayFor("orderTypes") as? [String]
        model.icebergAllowed = dic.boolFor("icebergAllowed")
        model.ocoAllowed = dic.boolFor("ocoAllowed")
        model.isSpotTradingAllowed = dic.boolFor("isSpotTradingAllowed")
        model.isMarginTradingAllowed = dic.boolFor("isMarginTradingAllowed")
        model.filters = dic["filters"] as? [[String: Any]]
        model.permissions = dic.arrayFor("permissions") as? [String]
        return model
    }
    
    open var lotSz: String? {
        if filters == nil {
            return nil
        }
        for dic in filters! {
            if let filterType = dic.stringFor("filterType"),
               filterType == "LOT_SIZE" {
                return dic.stringFor("stepSize")
            }
        }
        return nil
    }
    
    open var tickSz: String? {
        if filters == nil {
            return nil
        }
        for dic in filters! {
            if let filterType = dic.stringFor("filterType"),
               filterType == "PRICE_FILTER" {
                return dic.stringFor("tickSize")
            }
        }
        return nil
    }
}
