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
    
    open var serverErrorMsg: String? {
        if self.code != nil && self.msg != nil {
            return self.msg
        }
        return nil
    }
    
    open var errorMsg: String? {
        if fetchSucceed {
            return serverErrorMsg
        } else {
            return systemErrorMsg
        }
    }
}
