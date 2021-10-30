//
//  BAResiAPI.swift
//  SmartCurrency (iOS)
//
//  Created by shutut on 2021/8/17.
//

import Foundation
import SSCommon
import SSNetwork

open class BARestAPI: NSObject {
    open class func sendRequestWith(path: String,
                               params: Any? = nil,
                               method: SSHttpMethod? = nil,
                               dataKey: String = "data",
                               completion: @escaping (BAResponse) -> Void) {
        var newMethod = method
        var newPath = path
        
        if newPath.hasPrefix("GET") {
            newMethod = .GET
            newPath = newPath.replacingOccurrences(of: "\(SSHttpMethod.GET) ", with: "")
        } else if newPath.hasPrefix("POST") {
            newMethod = .POST
            newPath = newPath.replacingOccurrences(of: "\(SSHttpMethod.POST) ", with: "")
        } 
        
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
        
        var newParams = [String: Any]()
        if let dic = params as? [String: Any] {
            newParams.merge(dic) { _, new in
                new
            }
        }
        
        var sendParams: Any?
        var paramStr = newParams.urlQueryStr ?? ""
        if needSign {
            if newParams["timestamp"] == nil {
                let timestamp = Int(Date().timeIntervalSince1970 * 1000.0)
                newParams["timestamp"] = timestamp
            }
            paramStr = newParams.urlQueryStr!
            let sign = paramStr.hmacToSha256StringWith(key: APIKeyConfig.default.Ba_Secret_Key)
            paramStr = "\(paramStr)&signature=\(sign)"
        }
        
        if newMethod == .POST {
            sendParams = paramStr
        } else {
            urlStr = "\(urlStr)?\(paramStr)"
        }
        
        var headerFields = [String: String]()
        headerFields["X-MBX-APIKEY"] = APIKeyConfig.default.Ba_Api_Key
        headerFields["Accept"] = "application/json"
        
        let print = path.contains("order")
        let _ = SSNetworkHelper.sendRequest(urlStr: urlStr, params: sendParams, header: headerFields, method: newMethod!, timeOut: 10, printLog: print) { res in
            let response = BAResponse.init(response: res)
            if let dictionary = response.originJson as? [String: Any] {
                response.code = Int(dictionary["code"] as? String ?? "")
                response.msg = dictionary["msg"] as? String
                
                let da = dictionary[dataKey]
                response.data = da
            }
            completion(response)
        }
    }
    
    open class func sendRequestWith<T: Decodable>(path: String,
                                             params: Any? = nil,
                                             method: SSHttpMethod? = nil,
                                             dataKey: String = "data",
                                             dataClass: T.Type,
                                             completion: @escaping (BAResponse) -> Void) {
        sendRequestWith(path: path, params: params, method: method, dataKey: dataKey) { response in
            if response.responseSucceed {
                let da = response.data
                if da is [String: Any] {
                    if let dic = da as? [String: Any],
                       let dataModel = dic.transformToModel(dataClass.self) {
                        response.data = dataModel
                    }
                } else if da is [Any] {
                    if let array = da as? [[String: Any]],
                       let models = array.transformToModelArray(dataClass.self) {
                        response.data = models
                    }
                }
            }
            
            completion(response)
        }
    }
}