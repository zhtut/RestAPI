//
//  BAResiAPI.swift
//  SmartCurrency (iOS)
//
//  Created by shutut on 2021/8/17.
//

import Foundation
import SSEncrypt
import SSNetwork

open class BARestAPI: NSObject {
    open class func sendRequestWith(path: String,
                                    params: Any? = nil,
                                    method: SSHttpMethod = .GET,
                                    dataKey: String = "",
                                    completion: @escaping (BAResponse) -> Void) {
        var newMethod = method
        var newPath = path
        
        if newPath.hasPrefix("GET") {
            newMethod = .GET
            newPath = newPath.replacingOccurrences(of: "\(SSHttpMethod.GET) ", with: "")
        } else if newPath.hasPrefix("POST") {
            newMethod = .POST
            newPath = newPath.replacingOccurrences(of: "\(SSHttpMethod.POST) ", with: "")
        } else if newPath.hasPrefix("DELETE") {
            newMethod = .DELETE
            newPath = newPath.replacingOccurrences(of: "\(SSHttpMethod.DELETE) ", with: "")
        } else if newPath.hasPrefix("PUT") {
            newMethod = .PUT
            newPath = newPath.replacingOccurrences(of: "\(SSHttpMethod.PUT) ", with: "")
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
        let _ = SSNetworkHelper.sendRequest(urlStr: urlStr, header: headerFields, method: newMethod, timeOut: 10, printLog: print) { res in
            let response = BAResponse.init(response: res)
            if response.fetchSucceed {
                if let dictionary = response.originJson as? [String: Any] {
                    if dataKey.count > 0 {
                        let da = dictionary[dataKey]
                        response.data = da
                    } else {
                        response.data = response.originJson
                    }
                } else {
                    response.data = response.originJson
                }
            } else {
                if let dictionary = response.originJson as? [String: Any] {
                    response.code = Int(dictionary["code"] as? String ?? "")
                    response.msg = dictionary["msg"] as? String
                }
            }
            completion(response)
        }
    }
    
    open class func sendRequestWith<T: Decodable>(path: String,
                                                  params: Any? = nil,
                                                  method: SSHttpMethod = .GET,
                                                  dataKey: String = "",
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
