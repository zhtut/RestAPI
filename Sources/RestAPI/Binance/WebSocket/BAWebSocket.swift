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
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

open class BAWebSocket: NSObject, WebSocketDelegate {
    
    open var urlStr: String {
        ""
    }
    
    open var autoConnect: Bool {
        true
    }
    
    open var autoReConnect: Bool {
        true
    }
    
    open var didOpenHandler: (() -> Void)?
    
    var websocket: NIOWebSocket?
    
    open func open(force: Bool = false) {
        if websocket?.state == .connected {
            if force {
                log("websocket已是连接状态，断开当前连接，重新起一个实例去连")
                Task {
                    try await websocket?.close()
                }
            } else {
                log("websocket已是连接状态，不需要连接")
                return
            }
        }
        guard let url = URL(string: urlStr) else {
            log("生成URL失败：\(urlStr)")
            return
        }
        log("准备开始连接Wss：\(urlStr)")
        let req = URLRequest(url: url)
        websocket = NIOWebSocket(request: req)
        websocket?.delegate = self
        websocket?.open()
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
//        log("webSocketDidReceive：\(String(describing: message.jsonStr))")
    }
    
    // MARK: 代理
    
    open func webSocketDidOpen() {
        log("\(urlStr) webSocketDidOpen")
        didOpenHandler?()
        didOpenHandler = nil
    }
    
    open func webSocketDidReceivePing() {
        log("收到ping")
    }
    
    open func webSocketDidReceivePong() {
        log("收到pong")
    }
    
    open func webSocket(didReceiveMessageWith string: String) {
        if let data = string.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
           let dic = json as? [String: Any] {
            self.webSocketDidReceive(message: dic)
        }
    }
    
    public func webSocket(didReceiveMessageWith data: Data) {
        if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
           let dic = json as? [String: Any] {
            self.webSocketDidReceive(message: dic)
        }
    }
    
    open func webSocket(didCloseWithCode code: Int, reason: String?) {
        logErr("websocket断开连接\(urlStr)，code: \(code)，原因：\(reason ?? "")")
        if autoReConnect {
            open(force: true)
        }
    }
    
    open func webSocket(didFailWithError error: Error) {
        logErr("websocket收到错误：\(error)")
        if autoReConnect {
            open()
        }
    }
}
