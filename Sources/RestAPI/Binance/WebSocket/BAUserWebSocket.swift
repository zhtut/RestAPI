//
//  BAUserWebSocket.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/23.
//

import Foundation
import SSCommon

open class BAUserWebSocket: BAWebSocket {
    
    public static let shared = BAUserWebSocket()
    
    var listenKey: String?
    
    var completions = [String: SSSucceedHandler]()
    
    open override var autoConnect: Bool {
        false
    }
    
    open override var urlStr: String {
        let listenKey = listenKey ?? ""
        return "wss://fstream.binance.com/ws/\(listenKey.lowercased())"
    }
    
    public override init() {
        super.init()
        refreshListenKey()
        DispatchQueue.main.asyncAfter(deadline: .now() + 30 * 60) {
            self.startPutListenKey()
        }
    }
    
    func refreshListenKey() {
        createListenKey { succ, errMsg in
            if succ {
                self.open()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.refreshListenKey()
                }
            }
        }
    }
    
    func createListenKey(completion: @escaping SSSucceedHandler) {
        let path = "POST /fapi/v1/listenKey (HMAC SHA256)"
        BARestAPI.sendRequestWith(path: path) { response in
            if response.responseSucceed {
                if let data = response.data as? [String: Any],
                   let listenKey = data.stringFor("listenKey") {
                    self.listenKey = listenKey
                    completion(true, nil)
                    return
                }
            }
            completion(false, response.errMsg)
        }
    }
    
    func startPutListenKey() {
        let path = "PUT /fapi/v1/listenKey (HMAC SHA256)"
        BARestAPI.sendRequestWith(path: path) { response in
            if response.responseSucceed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 30 * 60) {
                    self.startPutListenKey()
                }
            }
        }
    }
    
    open override func webSocketDidOpen() {
         super.webSocketDidOpen()
    }
    
    open override func webSocketDidReceive(message: [String: Any]) {
        super.webSocketDidReceive(message: message)
        if let e = message["e"] as? String {
            if e == "listenKeyExpired" {
                refreshListenKey()
            }
        } else if let subbed = message["subbed"] as? String {
            for key in completions.keys {
                if key == subbed {
                    let completion = completions[key]!
                    if let status = message["status"] as? String {
                        if status == "ok" {
                            completion(true, nil)
                        } else {
                            completion(false, "订阅失败：\(message["msg"] ?? "")")
                        }
                    }
                    completions.removeValue(forKey: key)
                    return
                }
            }
        } else if let stream = message.stringFor("stream") {
            if stream.hasSuffix("@bookTicker") {
                
            }
        }
    }
}
