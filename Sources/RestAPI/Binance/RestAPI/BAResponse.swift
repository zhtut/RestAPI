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
    
    open var serverErrMsg: String? {
        if self.code != nil && self.msg != nil {
            return self.msg
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
