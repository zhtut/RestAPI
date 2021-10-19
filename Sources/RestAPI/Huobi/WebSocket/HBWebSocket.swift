//
//  HBWebSocket.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/18.
//

import Foundation
import Gzip
import SSCommon

class HBWebSocket: SCWebSocket {
    
    var gzipData: Bool {
        true
    }
    
    override func webSocketDidReceive(message: [String: Any]) {
        super.webSocketDidReceive(message: message)
        if let ping = message["ping"] {
            let pong = ["pong": ping]
            self.sendMessage(message: pong)
        } else if message["action"] as? String == "ping",
                  let data = message["data"] as? [String: Any],
                  let ts = data["ts"] {
            let pong = ["action": "pong", "data": [ "ts": ts ]] as [String : Any];
            self.sendMessage(message: pong)
        }
    }
    
    override func webSocketDidReceive(string: String) {
        super.webSocketDidReceive(string: string)
        /*
         "{\"event\":\"error\",\"msg\":\"Illegal request: {\\\"arg\\\":{\\\"channel\\\":\\\"candle1D\\\",\\\"instId\\\":\\\"BTC-USDT\\\"},\\\"event\\\":\\\"subscribe\\\"}\",\"code\":\"60012\"}"
         */
        if let data = string.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
            let dic = json as! [String: Any]
            log("HB.didReceiveMessageWithString:\(dic)")
            webSocketDidReceive(message: dic)
        }
    }
    
    override func webSocketDidReceive(data: Data) {
        super.webSocketDidReceive(data: data)
        if gzipData {
            if let nsdata = try? data.gunzipped(),
               let json = try? JSONSerialization.jsonObject(with: nsdata, options: .allowFragments) {
                let dic = json as! [String: Any]
                log("HB.didReceiveMessageWithNSData:\(dic)")
                webSocketDidReceive(message: dic)
            }
        } else {
            if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
                let dic = json as! [String: Any]
                log("HB.didReceiveMessageWithData:\(dic)")
                webSocketDidReceive(message: dic)
            }
        }
    }

}
