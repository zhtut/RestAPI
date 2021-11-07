//
//  OKWebSocket.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/14.
//

import Foundation
import SSCommon
#if canImport(Dispatch)
import Dispatch
#endif
import SSWebsocket
import SSLog

open class OKWebSocket: SSWebSocket {
    
    open var subArg: OKSubscribeArg?
    
    open func subscribe(channel: String,
                   instId: String? = nil,
                   instType: String? = nil,
                   ccy: String? = nil,
                   uly: String? = nil) {
        var arg = argWith(instId: instId?.uppercased(),
                          instType: instType,
                          ccy: ccy,
                          uly: uly)
        var dic = [ "op": "subscribe" ] as [String: Any]
        arg["channel"] = channel
        dic["args"] = [ arg ]
        sendMessage(message: dic)
    }
    
    open func subscribe(arg: OKSubscribeArg) {
        subArg = arg
        let arg = arg.transformToJson()
        var dic = [ "op": "subscribe" ] as [String: Any]
        dic["args"] = [ arg ]
        sendMessage(message: dic)
    }
    
    open func unsubscribe(channel: String,
                     instId: String? = nil,
                     instType: String? = nil,
                     ccy: String? = nil,
                     uly: String? = nil) {
        var dic = [ "op": "unsubscribe" ] as [String: Any]
        var arg = argWith(instId: instId,
                          instType: instType,
                          ccy: ccy,
                          uly: uly)
        arg["channel"] = channel
        dic["args"] = [ arg ]
        sendMessage(message: dic)
    }
    
    open func argWith(
        instId: String? = nil,
        instType: String? = nil,
        ccy: String? = nil,
        uly: String? = nil) -> [String: Any] {
        var arg = [String: Any]()
        if instId != nil {
            arg["instId"] = instId!
        }
        if instType != nil {
            arg["instType"] = instType!
        }
        if ccy != nil {
            arg["ccy"] = ccy!
        }
        if uly != nil {
            arg["uly"] = uly!
        }
        return arg
    }
    
    open override func webSocketDidOpen() {
        super.webSocketDidOpen()
        sendPing()
    }
    
    open override func webSocketDidReceive(message: [String : Any]) {
        super.webSocketDidReceive(message: message)
//        let str = message.jsonStr
//        log("WebsocketDidReceive:\(str ?? "")")
        if let event = message["event"] as? String,
           let arg = message["arg"] as? [String: Any],
           let channel = arg["channel"] as? String,
           let subArg = self.subArg {
            if event == "subscribe" {
                if channel == subArg.channel,
                   subArg.completion != nil {
                    subArg.completion!(true, nil)
                    self.subArg = nil
                }
            } else if event == "error",
                      let msg = message["msg"] as? String {
                if subArg.completion != nil {
                    subArg.completion!(false, "订阅失败\(msg)")
                    self.subArg = nil
                }
            }
        }
    }
    
    open override func webSocketDidReceive(string: String) {
        super.webSocketDidReceive(string: string)
        /*
         "{\"event\":\"error\",\"msg\":\"Illegal request: {\\\"arg\\\":{\\\"channel\\\":\\\"candle1D\\\",\\\"instId\\\":\\\"BTC-USDT\\\"},\\\"event\\\":\\\"subscribe\\\"}\",\"code\":\"60012\"}"
         */
//        log("OK.didReceiveMessageWith:\(string)")
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
