//
//  BAWebSocket.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/21.
//

import Foundation
import SSCommon
import SSWebsocket
import SSLog
#if canImport(Dispatch)
import Dispatch
#endif

open class BAWebSocket: SSWebSocket {
    
    open override var autoConnect: Bool {
        false
    }
    
//    open func subscribe(method: String = "SUBSCRIBE",
//                   params: [String]) {
//        let dic = [ "method": method, "params": params, "id": Int(Date().timeIntervalSince1970)] as [String: Any]
//        print("BAWebsocket.send:\(dic.jsonStr ?? "")")
//        sendMessage(message: dic)
//    }
//
//    open func unsubscribe(method: String = "UNSUBSCRIBE",
//                   params: [String]) {
//        let dic = [ "method": method, "params": params, "id": Int(Date().timeIntervalSince1970) ] as [String: Any]
//        sendMessage(message: dic)
//    }
    
    open func webSocketDidReceive(message: [String: Any]) {
        
    }
    
    // MARK: 代理
    
    open override func webSocketDidOpen() {
        super.webSocketDidOpen()
        log("\(urlStr) webSocketDidOpen")
    }
    
    open override func webSocketDidReceivePing() {
        super.webSocketDidReceivePing()
        log("收到ping")
    }
    
    open override func webSocketDidReceivePong() {
        super.webSocketDidReceivePong()
        log("收到pong")
    }
    
    open override func webSocket(didReceiveMessageWith string: String) {
        super.webSocket(didReceiveMessageWith: string)
        DispatchQueue.global().async {
            if let data = string.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
               let dic = json as? [String: Any] {
                DispatchQueue.main.async {
                    self.webSocketDidReceive(message: dic)
                }
            }
        }
    }
    
    open override func webSocket(didCloseWithCode code: Int, reason: String?) {
        super.webSocket(didCloseWithCode: code, reason: reason)
        sendPushNotication("websocket断开连接\(urlStr)，code: \(code)，原因：\(reason ?? "")", atSelf: true)
        open()
    }
    
    open override func webSocket(didFailWithError error: Error) {
        super.webSocket(didFailWithError: error)
        sendPushNotication("websocket收到错误：\(error)", atSelf: true)
    }
}
