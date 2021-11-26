//
//  OKBalancePosition.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/15.
//

import Foundation

public struct OKBalancePosition: Codable {

    public var balData: [OKBalData]?
    public var eventType: String? ///< ":"filled",
    public var pTime: String? ///< ":"1628959156597",
    public var posData: [OKPosition]?
}

public struct OKBalData: Codable {
    
    public var cashBal: String? ///< ":"374.749996037394299",
    public var ccy: String? ///< ":"USDT",
    public var uTime: String? ///< ":"1628959156597"
    public var availEq: String?
}
