//
//  STBaseResponse.swift
//  SmartTrader
//
//  Created by zhtg on 2021/3/20.
//

import Foundation
import SSCommon
import SSNetwork

open class STResponse: SSResponse {
    
    open var status: String?
    open var data: Any?
    open var ts: Int?

    open var responseSucceed: Bool {
        return status == "ok"
    }

    open var serverErrorMsg: String? {
        let originDictionary = originJson as? [String: Any]
        if originDictionary == nil {
            return nil
        }
        let err_msg = originDictionary?["err-msg"] as? String
        let err_msg2 = originDictionary?["err_msg"] as? String
        if err_msg != nil || err_msg2 != nil {
            var msg: String?
            if err_msg != nil {
                msg = err_msg!
            } else {
                msg = err_msg2!
            }
            return msg
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
