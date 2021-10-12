//
//  OkexSubscribeArg.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/21.
//

import Foundation
import SSCommon

open class OkexSubscribeArg: NSObject, Codable {
    open var channel: String?
    open var instId: String?
    open var instType: String?
    open var ccy: String?
    open var uly: String?
    open var completion: SSSucceedHandler?
    
    private enum CodingKeys: String, CodingKey {
        case channel, instId, instType, ccy, uly
    }
}
