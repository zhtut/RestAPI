//
//  BAResponse.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/20.
//

import Foundation
import SSCommon
import SSNetwork

public struct BAResponse {
    
    public var res: SSResponse
    
    init(res: SSResponse) async {
        self.res = res
        if let json = await res.bodyJson {
            if res.succeed {
                if let _ = res.modelType {
                    self.data = self.res.model
                } else {
                    self.data = await self.res.data
                }
            } else {
                if let dict = json as? [String: Any] {
                    self.code = dict["code"] as? Int
                    self.msg = dict["msg"] as? String
                }
            }
        }
    }
    
    public var code: Int?
    public var data: Any?
    public var msg: String?
    
    public var responseSucceed: Bool {
        if res.succeed {
            return code == nil || code == 200
        }
        return false
    }
    
    public var errMsg: String? {
        if self.code != nil && self.msg != nil {
            return self.msg
        }
        return res.error?.localizedDescription
    }
}
