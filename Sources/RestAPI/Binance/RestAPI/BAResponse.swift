//
//  BAResponse.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/20.
//

import Foundation
import SSCommon
import SSNetwork

open class BAResponse: SSResponse {

    open var code: Int?
    open var data: Any?
    open var msg: String?
    
    open var responseSucceed: Bool {
        return code == nil
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
