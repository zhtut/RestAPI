//
//  BAResponse.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/20.
//

import Foundation
import SSCommon

class BAResponse: SSResponse {

    var code: Int?
    var data: Any?
    var msg: String?
    
    var responseSucceed: Bool {
        return code == nil
    }
    
    var serverErrorMsg: String? {
        if self.code != nil && self.msg != nil {
            return self.msg
        }
        return nil
    }
    
    var errorMsg: String? {
        if fetchSucceed {
            return serverErrorMsg
        } else {
            return systemErrorMsg
        }
    }
}
