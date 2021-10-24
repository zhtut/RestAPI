//
//  STURLInfo.swift
//  SmartTrader
//
//  Created by zhtg on 2021/3/20.
//

import Foundation
import SSCommon
import SSNetwork

class STURLInfo : NSObject {
    
    var url = ""
    var params = [String: Any]()
    
    class func urlInfoWith(method: SSHttpMethod, host: String, path: String, params: [String: Any]?) -> STURLInfo {
        var signatureParams = requiredParams()
        if params != nil,
           let time = params!.stringFor("Timestamp"),
           time.count > 0 {
            signatureParams["Timestamp"] = time
        }
        var noSignatureParams = [String: Any]()
        if params != nil {
            if method == .GET {
                signatureParams.merge(params!) { (_, new) in new }
            } else {
                noSignatureParams.merge(params!) { (_, new) in new }
            }
        }
        
        var newPath = path
        if !path.hasPrefix("/") {
            newPath = "/\(path)"
        }
        
        let signature = signatureWith(method: method, host: host, path: newPath, params: signatureParams)
        signatureParams["Signature"] = signature
        
        let urlString = "\(host)\(path)"
        
        let urlInfo = STURLInfo()
        urlInfo.url = getURLWith(urlString: urlString, params: signatureParams)
        urlInfo.params = noSignatureParams
        return urlInfo
    }
    
    class func getURLWith(urlString: String, params: [String: Any]) -> String {
        var temp = urlString
        let paramString = getParamString(params)!
        if temp.contains("?") {
            temp.append("&\(paramString)")
        } else {
            temp.append("?\(paramString)")
        }
        return temp
    }
    
    class func signatureWith(method: SSHttpMethod, host: String, path: String, params: [String: Any]?) -> String {
        
        var newHost = host
        if newHost.hasPrefix("http") {
            newHost = newHost.components(separatedBy: "//").last ?? ""
        }
        
        var newPath = path
        if !path.hasPrefix("/") {
            newPath = "/\(path)"
        }
        
        var originStr = "\(method)\n"
        originStr.append("\(newHost)\n")
        originStr.append("\(newPath)\n")
        
        if params != nil {
            let paramString = getParamString(params!)
            originStr.append(paramString!)
        }
        let signature = originStr.hmacToBase64StringWith(key: APIKeyConfig.default.HB_Secret_Key)
        return signature
    }
    
    class func getParamString(_ params: [String: Any]) -> String? {
        var originStr = ""
        let keys = params.keys.sorted()
        for i in 0...keys.count-1 {
            let key = keys[i]
            if let value = params[key] as? String {
                if i == 0 {
                    originStr.append("\(key)=\(value.urlEncodeString()!)")
                } else {
                    originStr.append("&\(key)=\(value.urlEncodeString()!)")
                }
            }
        }
        
        return originStr
    }
    
    class func requiredParams() -> [String: Any] {
        var params = [String: Any]()
        params["AccessKeyId"] = APIKeyConfig.default.HB_Access_Key
        params["SignatureMethod"] = "HmacSHA256"
        params["SignatureVersion"] = "2"
        params["Timestamp"] = Date().utcString
        return params
    }
}
