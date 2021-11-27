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

open class OKRestAPI: NSObject {
    
    open class func sendRequestWith(path: String,
                                    params: Any? = nil,
                                    method: SSHttpMethod = .GET,
                                    dataKey: String = "data",
                                    completion: @escaping (OKResponse) -> Void) {
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
        
        if !newPath.hasPrefix("/") {
            newPath = "/\(newPath)"
        }
        
        let timestamp = Date().isoTimeString
        
        var headerFields = [String: String]()
        headerFields["OK-ACCESS-KEY"] = APIKeyConfig.default.OK_API_KEY
        headerFields["OK-ACCESS-TIMESTAMP"] = timestamp
        headerFields["OK-ACCESS-PASSPHRASE"] = APIKeyConfig.default.OK_Passphrase
        headerFields["Content-Type"] = "application/json; charset=UTF-8"
        headerFields["Accept"] = "application/json"
        
        var bodyString: String?
        if newMethod == .POST {
            if let pa = newParams,
               let data = try? JSONSerialization.data(withJSONObject: pa) {
                bodyString = String(data: data, encoding: .utf8) ?? ""
                newParams = bodyString
            }
        }
        var signPath = newPath
        if newMethod == .GET,
           let new = newParams {
            signPath = SSNetworkHelper.getURLString(url: newPath, params: new)
            newParams = nil
        }
        
        let urlStr = "\(APIKeyConfig.default.OK_BaseURL)\(signPath)"
        let sign = OKGetSign(timestamp: timestamp, method: "\(newMethod)", path: signPath, bodyStr: bodyString)
        headerFields["OK-ACCESS-SIGN"] = sign
        
        let _ = SSNetworkHelper.sendRequest(urlStr: urlStr, params: newParams, header: headerFields, method: newMethod, timeOut: 10, printLog: false) { res in
            let response = OKResponse.init(response: res)
            if let dictionary = response.originJson as? [String: Any] {
                response.code = dictionary.intFor("code")
                response.msg = dictionary["msg"] as? String
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
                                                  completion: @escaping (OKResponse) -> Void) {
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
    
    open class func OKGetSign(timestamp: String, method: String, path: String, bodyStr: String?) -> String {
        var str = "\(timestamp)\(method)\(path)"
        if let bodyStr = bodyStr,
           bodyStr.count > 0 {
            str = "\(str)\(bodyStr)"
        }
        let base64String = str.hmacToBase64StringWith(key: APIKeyConfig.default.OK_SECRET_KEY);
        return base64String;
    }
}
