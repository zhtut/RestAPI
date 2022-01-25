//
//  OKResiAPI.swift
//  SmartCurrency
//
//  Created by shutut on 2021/7/28.
//

import Foundation
import SSCommon
import SSNetwork
import SSEncrypt

open class GIRestAPI: NSObject {
    
    open class func sendRequestWith(path: String,
                                    params: Any? = nil,
                                    method: SSHttpMethod = .GET,
                                    dataKey: String = "data",
                                    completion: @escaping (GIResponse) -> Void) {
        var newMethod = method
        var newPath = path
        var newParams = params
        
        if newPath.hasPrefix("GET") {
            newMethod = .GET
            newPath = newPath.replacingOccurrences(of: "\(SSHttpMethod.GET) ", with: "")
        } else if newPath.hasPrefix("POST") {
            newMethod = .POST
            newPath = newPath.replacingOccurrences(of: "\(SSHttpMethod.POST) ", with: "")
        }
        
        var urlStr: String
        let baseHost = APIKeyConfig.default.GI_BASE_HOST
        let basePath = APIKeyConfig.default.GI_BASE_PATH
        if newPath.hasPrefix("/") {
            urlStr = "\(baseHost + basePath)\(newPath)"
        } else {
            urlStr = "\(baseHost + basePath)/\(newPath)"
        }
        
        let timestamp = "\(Int(Date().timeIntervalSince1970))"
        
        var headerFields = [String: String]()
        headerFields["KEY"] = APIKeyConfig.default.GI_Api_Key
        headerFields["Timestamp"] = timestamp
        headerFields["Content-Type"] = "application/json"
        headerFields["Accept"] = "application/json"
        
        var bodyString: String?
        if newMethod == .POST,
           let pa = params,
           let data = try? JSONSerialization.data(withJSONObject: pa, options: .prettyPrinted) {
            bodyString = String(data: data, encoding: .utf8) ?? ""
            newParams = bodyString
        }
        
        var queryStr: String?
        if newMethod == .GET,
           let pa = params as? [String: Any],
           let query = pa.urlQueryStr {
            queryStr = query
            urlStr.append("?\(query)")
            newParams = nil
        }
        
        let sign = GIGetSign(timestamp: timestamp, method: "\(newMethod)", path: basePath + newPath, queryStr: queryStr, bodyStr: bodyString)
        headerFields["SIGN"] = sign
        
        let _ = SSNetworkHelper.sendRequest(urlStr: urlStr, params: newParams, header: headerFields, method: newMethod, timeOut: 10, printLog: false) { res in
            let response = GIResponse.init(response: res)
            if let dictionary = response.originJson as? [String: Any] {
                response.label = dictionary.stringFor("label")
                response.message = dictionary.stringFor("message")
                if !response.responseSucceed {
                    response.logResponse()
                }
                let da = dictionary[dataKey]
                response.data = da
            }
            completion(response)
        }
    }
    
    open class func sendRequestWith<T: Decodable>(path: String,
                                                  params: Any? = nil,
                                                  method: SSHttpMethod = .GET,
                                                  dataKey: String = "data",
                                                  dataClass: T.Type,
                                                  completion: @escaping (GIResponse) -> Void) {
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
    
    open class func GIGetSign(timestamp: String, method: String, path: String, queryStr: String?, bodyStr: String?) -> String {
        var str = ""
        str.append("\(method.uppercased())\n")
        str.append("\(path)\n")
        str.append("\(queryStr ?? "")\n")
        
        let body = (bodyStr ?? "").sha512Signature()
        str.append("\(body)\n")
        str.append(timestamp)
        let sign = str.hmacSha512With(key: APIKeyConfig.default.GI_Secret_Key);
        return sign;
    }
}
