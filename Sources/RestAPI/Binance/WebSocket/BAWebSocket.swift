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

class BAWebSocket: SCWebSocket {
    
    func subscribe(method: String = "SUBSCRIBE",
                   params: [String]) {
        let dic = [ "method": method, "params": params ] as [String: Any]
        sendMessage(message: dic)
    }
    
    func unsubscribe(method: String = "UNSUBSCRIBE",
                   params: [String]) {
        let dic = [ "method": method, "params": params ] as [String: Any]
        sendMessage(message: dic)
    }
    
    override func webSocketDidOpen() {
        super.webSocketDidOpen()
        sendPing()
    }
    
    override func webSocketDidReceive(message: [String: Any]) {
        super.webSocketDidReceive(message: message)
    }
    
    override func webSocketDidReceive(string: String) {
        super.webSocketDidReceive(string: string)
//        log("BA.didReceiveMessageWith:\(string)")
        if string == "pong" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                if self.isConnected {
                    self.sendPing()
                }
            }
        } else {
            if let data = string.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
                let dic = json as! [String: Any]
                webSocketDidReceive(message: dic)
            }
        }
    }
}
