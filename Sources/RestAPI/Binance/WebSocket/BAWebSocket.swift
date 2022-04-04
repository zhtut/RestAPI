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
    
    open func subscribe(method: String = "SUBSCRIBE",
                   params: [String]) {
        let dic = [ "method": method, "params": params, "id": Int(Date().timeIntervalSince1970)] as [String: Any]
        print("BAWebsocket.send:\(dic.jsonStr ?? "")")
        sendMessage(message: dic)
    }
    
    open func unsubscribe(method: String = "UNSUBSCRIBE",
                   params: [String]) {
        let dic = [ "method": method, "params": params, "id": Int(Date().timeIntervalSince1970) ] as [String: Any]
        sendMessage(message: dic)
    }
    
    open override func webSocketDidOpen() {
        super.webSocketDidOpen()
        sendPing()
    }
    
    open func webSocketDidReceive(message: [String: Any]) {
        
    }
    
    open override func webSocket(didReceiveMessageWith string: String) {
        super.webSocket(didReceiveMessageWith: string)
        if string == "pong" {
            log("websocket.ba收到pong")
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                if self.isConnected {
                    self.sendPing()
                }
            }
        } else if string == "ping" {
            log("websocket.ba收到ping")
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                if self.isConnected {
                    self.webSocket?.send("pong")
                }
            }
        } else {
            if let data = string.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
               let dic = json as? [String: Any] {
                webSocketDidReceive(message: dic)
            }
        }
    }
    
    open override func webSocket(didCloseWithCode code: Int, reason: String?) {
        super.webSocket(didCloseWithCode: code, reason: reason)
        log("websocket断开连接\(urlStr)，code: \(code)，原因：\(reason ?? "")")
        open()
    }
    
    open override func webSocket(didFailWithError error: Error) {
        super.webSocket(didFailWithError: error)
        log("websocket收到错误：\(error)")
    }
}
