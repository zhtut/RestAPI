//
//  OkexBalancePosition.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/15.
//

import Foundation

public struct OkexBalancePosition: Codable {

    public var balData: [OkexBalData]?
    public var eventType: String? ///< ":"filled",
    public var pTime: String? ///< ":"1628959156597",
    public var posData: [OkexPosition]?
}

public struct OkexBalData: Codable {
    
    public var cashBal: String? ///< ":"374.749996037394299",
    public var ccy: String? ///< ":"USDT",
    public var uTime: String? ///< ":"1628959156597"
}
