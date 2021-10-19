//
//  STHBRestAPI.swift
//  SmartTrader
//
//  Created by zhtg on 2021/3/20.
//

import Foundation
import SSCommon

class STRestAPI : NSObject {
    
    class func sendRequestWith(path: String,
                               params: Any? = nil,
                               method: SSHttpMethod? = nil,
                               dataKey: String = "data",
                               completion: @escaping (STResponse) -> Void) {
        var baseHost: String
        if path.contains("swap") || path.contains("contanct") {
            baseHost = APIKeyConfig.default.HB_Swap_BaseURL
        } else {
            baseHost = APIKeyConfig.default.HB_Spot_BaseURL
        }

        let meth = method ?? .GET
        let dic = params as? [String: Any]
        let urlInfo = STURLInfo.urlInfoWith(method: meth, host: baseHost, path: path, params: dic)
        let header = ["Content-Type": "application/json"]
        let print = path.contains("order")
        let _ = SSNetworkHelper.sendRequest(url: urlInfo.url, params: urlInfo.params, header: header, method: meth, timeOut: 10, printLog: print) { res in
            let response = STResponse.init(response: res)
            if let dictionary = response.originJson as? [String: Any] {
                response.ts = dictionary.intFor("ts")
                response.status = dictionary["status"] as? String
                
                let da = dictionary[dataKey]
                response.data = da
            }
            completion(response)
        }
    }
    
    class func sendRequestWith<T: Decodable>(path: String,
                                             params: Any? = nil,
                                             method: SSHttpMethod? = nil,
                                             dataKey: String = "data",
                                             dataClass: T.Type,
                                             completion: @escaping (STResponse) -> Void) {
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
