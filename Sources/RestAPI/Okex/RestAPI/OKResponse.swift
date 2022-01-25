//
//  OKResponse.swift
//  SmartCurrency
//
//  Created by shutut on 2021/7/28.
//

import Foundation
import SSNetwork

open class OKResponse: SSResponse {
    
    open var code: Int?
    open var data: Any?
    open var msg: String?
    
    open var responseSucceed: Bool {
        return code == 0
    }
    
    open var serverErrMsg: String? {
        if let _ = code,
           let msg = msg {
            return msg
        }
        return nil
    }
    
    open var errMsg: String? {
        if fetchSucceed {
            return serverErrMsg
        } else {
            return systemErrMsg
        }
    }
}
