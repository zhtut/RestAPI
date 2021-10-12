//
//  OkexMarketWebSocket.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/14.
//

import Foundation
import SSCommon
import SSLog

class OkexMarketWebSocket: OkexWebSocket {
    
    static let shared = OkexMarketWebSocket()
    
    override var urlStr: String {
        "wss://wsaws.okex.com:8443/ws/v5/public"
//        "wss://wsaws.okex.com:8443/ws/v5/public"
    }
    
    var depthData = OkexDepthData()
    
    /// k线图变化的通知
    static let candleDidChangeNotification = Notification.Name("SCCandleDidChangeNotification")
    
    override func webSocketDidReceive(message: [String : Any]) {
        super.webSocketDidReceive(message: message)
        let event = message["event"] as? String;
        let arg = message["arg"] as? [String: Any];
        let channel = arg?["channel"] as? String ?? ""
        if event == "subscribe" && arg != nil {
            if channel.hasPrefix("candle") {
                log("K线频道订阅成功")
            } else if channel.hasPrefix("book") {
                log("深度频道订阅成功")
            } else if channel == "trades" {
                log("交易记录频道订阅成功")
            }
        } else {
            if channel.hasPrefix("candle") {
                processCandleMessage(message: message)
            } else if channel.hasPrefix("books") {
                if let action = message["action"] as? String,
                   let data = message["data"] as? [[String : Any]] {
                    if action == "snapshot" {
                        depthData.setupWith(data: data)
                    } else if action == "update" {
                        depthData.updateWith(data: data)
                    }
                }
                print(depthData.description)
            } else if channel == "trades" {
//                if let data = message["data"] as? [[String : Any]] {
//                    let models = data.transformToModelArray(OkexHistoryTrade.self)
//                }
            }
        }
    }
    
    func processCandleMessage(message: [String: Any]) {
        if let data = message["data"] as? [[String]] {
            let first = data.first!
            let candle = OkexCandle.candleWith(data: first)
            NotificationCenter.default.post(name: OkexMarketWebSocket.candleDidChangeNotification, object: candle)
        }
    }
}
