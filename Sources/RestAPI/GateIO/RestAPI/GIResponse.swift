//
//  OKResponse.swift
//  SmartCurrency
//
//  Created by shutut on 2021/7/28.
//

import Foundation
import SSNetwork

open class GIResponse: SSResponse {
    
    open var label: String?
    open var data: Any?
    open var message: String?
    
    open var responseSucceed: Bool {
        if let response = originResponse as? HTTPURLResponse {
            if response.statusCode == 200 {
                return true
            }
        }
        return false
    }
    
    open var serverErrMsg: String? {
        if responseSucceed == false,
         let msg = message {
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
