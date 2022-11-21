//
//  BAResiAPI.swift
//  SmartCurrency (iOS)
//
//  Created by shutut on 2021/8/17.
//

import Foundation
import SSEncrypt
import SSNetwork

open class BARestAPI {
    @discardableResult
    open class func sendRequestWith(path: String,
                                    params: Any? = nil,
                                    method: SSHTTPMethod = .GET,
                                    dataKey: String? = nil,
                                    dataClass: Decodable.Type? = nil) async -> BAResponse {
        var newMethod = method
        var newPath = path
        
        if newPath.hasPrefix("GET") {
            newMethod = .GET
        } else if newPath.hasPrefix("POST") {
            newMethod = .POST
        } else if newPath.hasPrefix("DELETE") {
            newMethod = .DELETE
        } else if newPath.hasPrefix("PUT") {
            newMethod = .PUT
        }
        
        newPath = newPath.replacingOccurrences(of: "\(newMethod) ", with: "")
        
        var needSign = false
        if newPath.hasSuffix(" (HMAC SHA256)") {
            needSign = true
            newPath = newPath.replacingOccurrences(of: " (HMAC SHA256)", with: "")
        }
        
        var urlStr: String
        if newPath.hasPrefix("/") {
            urlStr = "\(APIKeyConfig.default.Ba_Base_URL_Str)\(newPath)"
        } else {
            urlStr = "\(APIKeyConfig.default.Ba_Base_URL_Str)/\(newPath)"
        }
        
        var paramStr = ""
        if let params = params as? [String: Any] {
            paramStr = params.urlQueryStr ?? ""
        }
        if needSign {
            var newParams = params as? [String: Any] ?? [String: Any]()
            newParams["timestamp"] = Int(Date().timeIntervalSince1970 * 1000.0)
            if let queryStr = newParams.urlQueryStr {
                let sign = queryStr.hmacSha256With(key: APIKeyConfig.default.Ba_Secret_Key)
                paramStr = "\(queryStr)&signature=\(sign)"
            }
        }
        
        if paramStr.count > 0 {
            urlStr = "\(urlStr)?\(paramStr)"
        }
        
        var headerFields = [String: String]()
        headerFields["X-MBX-APIKEY"] = APIKeyConfig.default.Ba_Api_Key
        headerFields["Accept"] = "application/json"
        
        let print = false
        let response = await SSNetwork.sendRequest(urlStr: urlStr, header: headerFields, method: newMethod, printLog: print, dataKey: dataKey, modelType: dataClass)
        let baRes = await BAResponse(res: response)
        return baRes
    }
}
