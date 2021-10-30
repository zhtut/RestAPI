//
//  OKMarketWebSocket.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/14.
//

import Foundation
import SSCommon
import SSLog

open class OKMarketWebSocket: OKWebSocket {
    
    public static let shared = OKMarketWebSocket()
    
    open override var urlStr: String {
        return APIKeyConfig.default.OK_WebsocketPublicURL
    }
    
    open var depthData = OKDepthData()
    
    /// k线图变化的通知
    public static let candleDidChangeNotification = Notification.Name("SCCandleDidChangeNotification")
    
    open var candles: [OKCandle]?
    
    open override func webSocketDidReceive(message: [String : Any]) {
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
//                    let models = data.transformToModelArray(OKHistoryTrade.self)
//                }
            }
        }
    }
    
    public enum CandleBar: String {
        case candle1Y
        case candle6M, candle3M, candle1M
        case candle1W
        case candle1D, candle2D, candle3D, candle5D
        case candle12H, candle6H, candle4H, candle2H, candle1H
        case candle30m, candle15m, candle5m, candle3m, candle1m
    }
    
    open func subscribeCandle(bar: CandleBar, instId: String) {
        let arg = OKSubscribeArg()
        arg.channel = "\(bar)"
        arg.instId = instId
        subscribe(arg: arg)
        
        let path = "GET /api/v5/market/candles"
        let params = ["instId": instId, "bar": "\(bar)".replacingOccurrences(of: "candle", with: ""), "limit": "12"]
        OKRestAPI.sendRequestWith(path: path, params: params) { response in
            self.candles = [OKCandle]()
            if response.responseSucceed {
                if let data = response.data as? [[String]] {
                    for obj in data {
                        let candle = OKCandle.candleWith(data: obj)
                        self.candles!.append(candle)
                    }
                }
            }
        }
    }
    
    open func processCandleMessage(message: [String: Any]) {
        guard var candles = candles else {
            return
        }
        
        if let data = message["data"] as? [[String]] {
            let first = data.first!
            var candle = OKCandle.candleWith(data: first)
            if let arg = message["arg"] as? [String: Any],
               let instId = arg.stringFor("instId") {
                candle.instId = instId
                if let last = candles.last {
                    if last.ts == candle.ts {
                        candles.removeLast()
                    }
                }
                candles.append(candle)
                self.candles = candles
            }
            NotificationCenter.default.post(name: OKMarketWebSocket.candleDidChangeNotification, object: candle)
        }
    }
}
