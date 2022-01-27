//
//  BAUserWebSocket.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/23.
//

import Foundation
import SSCommon
import SSLog

open class BAUserWebSocket: BAWebSocket {
    
    public static let shared = BAUserWebSocket()
    
    var listenKey: String?
    var completions = [String: SSSucceedHandler]()
    
    open var orders: [BAOrder]?
    open var positions: [BAPosition]?
    open var assets: [BAAsset]?
    
    open var busdBal: Double? {
        if let assets = assets {
            for asset in assets {
                if asset.asset == "BUSD" {
                    return asset.availableBalance.doubleValue
                }
            }
        }
        return nil
    }
    
    open override var autoConnect: Bool {
        false
    }
    
    open override var urlStr: String {
        return APIKeyConfig.default.BA_Websocket_URL_Str
    }
    
    public static let orderChangedNotification = Notification.Name("BAOrderChangedNotification")
    public static let accountChangedNotification = Notification.Name("BAAccountChangedNotification")
    
    public override init() {
        super.init()
        log("UserWebsocket初始化，准备请求ListenKey")
        refreshListenKey()
        DispatchQueue.main.asyncAfter(deadline: .now() + 30 * 60) {
            self.startPutListenKey()
        }
    }
    
    func refreshListenKey() {
        createListenKey { succ, errMsg in
            if succ {
                log("ListenKey请求成功，准备开始连接")
                self.open()
            } else {
                log("ListenKey请求失败：\(errMsg ?? "")，一秒后重试")
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
        
        log("userSocket已连接，准备开始订阅")
        
        let listenKey = listenKey ?? ""
        subscribe(params: [listenKey])
        
        log("开始刷新订单")
        refreshOrders()
        
        log("开始刷新账户信息")
        refreshAccount()
    }
    
    open override func webSocketDidReceive(message: [String: Any]) {
        super.webSocketDidReceive(message: message)
        log("BA.didReceiveMessageWith:\(message)")
        if let data = message["data"] as? [String: Any],
            let e = data["e"] as? String {
            if e == "listenKeyExpired" {
                refreshListenKey()
            } else if e == "ORDER_TRADE_UPDATE" {
                processOrder(message: message)
            } else if e == "ACCOUNT_UPDATE" {
                processAccount(message: message)
            }
        } else {
            log("other User websocket message:\(message.jsonStr ?? "")")
        }
    }
    
    func processOrder(message: [String: Any]) {
        if let a1 = message["data"] as? [String : Any],
           let data = a1["o"] as? [String: Any] {
            let order = BAOrder()
            order.symbol = data.stringFor("s") ?? ""
            order.clientOrderId = data.stringFor("c") ?? ""
            order.side = data.stringFor("S") ?? ""
            order.origType = data.stringFor("o") ?? ""
            order.timeInForce = data.stringFor("f") ?? ""
            order.origQty = data.stringFor("q") ?? ""
            order.price = data.stringFor("p") ?? ""
            order.avgPrice = data.stringFor("ap") ?? ""
            order.stopPrice = data.stringFor("sp") ?? ""
            order.status = data.stringFor("X") ?? ""
            order.orderId = data.stringFor("i") ?? ""
            order.executedQty = data.stringFor("z") ?? ""
            order.time = data.stringFor("T") ?? ""
            order.workingType = data.stringFor("wt") ?? ""
            order.origType = data.stringFor("ot") ?? ""
            order.positionSide = data.stringFor("ps") ?? ""
            var orders = orders?.filter({
                $0.orderId != order.orderId
            })
            if order.status == NEW ||
                order.status == PARTIALLY_FILLED {
                orders?.append(order)
            }
            self.orders = orders
            log("订单\(order.orderId)变化：\(order.status), 剩余订单数量：\(orders!.count)")
            NotificationCenter.default.post(name: BAUserWebSocket.orderChangedNotification, object: order)
        }
    }
    
    open func refreshOrders() {
        fetchPendingOrders { orders, errMsg in
            if let orders = orders {
                self.orders = orders
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.refreshOrders()
                }
            }
        }
    }
    
    func fetchPendingOrders(completion: @escaping ([BAOrder]?, String?) -> Void) {
        let path = "GET /fapi/v1/openOrders (HMAC SHA256)"
        BARestAPI.sendRequestWith(path: path, dataClass: BAOrder.self) { response in
            if let data = response.data as? [BAOrder] {
                completion(data, nil)
            } else {
                completion(nil, response.errMsg)
            }
        }
    }
    
    func processAccount(message: [String: Any]) {
        if let data = message["data"] as? [String : Any],
           let a = data["a"] as? [String: Any] {
            if let B = a["B"] as? [[String: Any]] {
                for b in B {
                    let a = b.stringFor("a")
                    for asset in assets ?? [BAAsset]() {
                        if a == asset.asset {
                            asset.walletBalance = b.stringFor("wb") ?? ""
                            asset.crossWalletBalance = b.stringFor("cw") ?? ""
                        }
                    }
                }
            }
            if let P = a["P"] as? [[String: Any]] {
                for p in P {
                    let s = p.stringFor("s") ?? ""
                    let ps = p.stringFor("ps") ?? "" // 持仓方向
                    let pa = p.stringFor("pa") ?? "" // 仓位
                    var find: BAPosition?
                    for position in positions ?? [BAPosition]() {
                        if position.symbol == s {
                            find = position
                            break
                        }
                    }
                    if let find = find {
                        if pa.doubleValue == 0.0 {
                            positions?.remove(find)
                        } else {
                            find.positionAmt = pa
                            find.entryPrice = p.stringFor("ep") ?? "" // 入仓价格
                            find.unrealizedProfit = p.stringFor("up") ?? "" // 持仓未实现盈亏
                            find.positionSide = ps
                        }
                    } else {
                        let newPosition = BAPosition()
                        newPosition.positionAmt = pa
                        newPosition.entryPrice = p.stringFor("ep") ?? "" // 入仓价格
                        newPosition.unrealizedProfit = p.stringFor("up") ?? "" // 持仓未实现盈亏
                        newPosition.positionSide = ps
                        positions?.append(newPosition)
                    }
                }
            }
        }
        NotificationCenter.default.post(name: BAUserWebSocket.accountChangedNotification, object: nil)
    }
    
    open func refreshAccount() {
        let path = "GET /fapi/v2/account (HMAC SHA256)"
        BARestAPI.sendRequestWith(path: path) { response in
            if let data = response.data as? [String: Any] {
                if let positions = data["positions"] as? [[String: Any]],
                   let models = positions.transformToModelArray(BAPosition.self) {
                    let avail = models.filter { position in
                        position.positionAmt.doubleValue! != 0.0
                    }
                    self.positions = avail
                } else {
                    self.positions = [BAPosition]()
                }
                if let assets = data["assets"] as? [[String: Any]],
                   let models = assets.transformToModelArray(BAAsset.self) {
                    self.assets = models
                } else {
                    self.assets = [BAAsset]()
                }
            } else {
                log("刷新Account失败：\(response.errMsg ?? "")")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.refreshAccount()
                }
            }
        }
    }
    
    /*
     订单成交时收到的推送
     2022-01-26 16:41:20:BA.didReceiveMessageWith:{"e":"ORDER_TRADE_UPDATE","T":1643186480846,"E":1643186480853,"o":{"s":"ETHBUSD","c":"ios_3pdK38TLtMRjqN6y5WBZ","S":"BUY","o":"LIMIT","f":"GTC","q":"0.003","p":"2487.51","ap":"0","sp":"0","x":"NEW","X":"NEW","i":2844843857,"l":"0","z":"0","L":"0","T":1643186480846,"t":0,"b":"7.46253","a":"0","m":false,"R":false,"wt":"CONTRACT_PRICE","ot":"LIMIT","ps":"BOTH","cp":false,"rp":"0","pP":false,"si":0,"ss":0}}
     2022-01-26 16:41:23:BA.didReceiveMessageWith:{"e":"ACCOUNT_UPDATE","T":1643186482920,"E":1643186482925,"a":{"B":[{"a":"BUSD","wb":"788.59145825","cw":"788.59145825","bc":"0"}],"P":[{"s":"ETHBUSD","pa":"0.003","ep":"2487.51000","cr":"0","up":"0.00077345","mt":"cross","iw":"0","ps":"BOTH","ma":"BUSD"}],"m":"ORDER"}}
     2022-01-26 16:41:23:BA.didReceiveMessageWith:{"e":"ORDER_TRADE_UPDATE","T":1643186482920,"E":1643186482925,"o":{"s":"ETHBUSD","c":"ios_3pdK38TLtMRjqN6y5WBZ","S":"BUY","o":"LIMIT","f":"GTC","q":"0.003","p":"2487.51","ap":"2487.51000","sp":"0","x":"TRADE","X":"FILLED","i":2844843857,"l":"0.003","z":"0.003","L":"2487.51","n":"-0.00074625","N":"BUSD","T":1643186482920,"t":87445238,"b":"0","a":"0","m":true,"R":false,"wt":"CONTRACT_PRICE","ot":"LIMIT","ps":"BOTH","cp":false,"rp":"0","pP":false,"si":0,"ss":0}}
     
     // 划转时收到的推送
     16:54:07:BA.didReceiveMessageWith:{"stream":"znwAi62B0krfvfENOI2zqq5VSOAMU21QGFDAYHxUckgQ3LezOV4Of7RnBbUnDSpo","data":{"e":"ACCOUNT_UPDATE","T":1643187247436,"E":1643187247442,"a":{"B":[{"a":"BUSD","wb":"1575.59145825","cw":"1575.59145825","bc":"787"}],"P":[],"m":"DEPOSIT"}}}
     
     // 清仓推送
     2022-01-26 17:35:04:BA.didReceiveMessageWith:{"stream":"znwAi62B0krfvfENOI2zqq5VSOAMU21QGFDAYHxUckgQ3LezOV4Of7RnBbUnDSpo","data":{"e":"ORDER_TRADE_UPDATE","T":1643189704431,"E":1643189704443,"o":{"s":"ETHBUSD","c":"ios_P6GCXs2KGbptudxYR9Wu","S":"SELL","o":"MARKET","f":"GTC","q":"0.003","p":"0","ap":"0","sp":"0","x":"NEW","X":"NEW","i":2845437381,"l":"0","z":"0","L":"0","T":1643189704431,"t":0,"b":"0","a":"0","m":false,"R":true,"wt":"CONTRACT_PRICE","ot":"MARKET","ps":"BOTH","cp":false,"rp":"0","pP":false,"si":0,"ss":0}}}
     2022-01-26 17:35:04:BA.didReceiveMessageWith:{"stream":"znwAi62B0krfvfENOI2zqq5VSOAMU21QGFDAYHxUckgQ3LezOV4Of7RnBbUnDSpo","data":{"e":"ACCOUNT_UPDATE","T":1643189704431,"E":1643189704443,"a":{"B":[{"a":"BUSD","wb":"1575.58581278","cw":"1575.58581278","bc":"0"}],"P":[{"s":"ETHBUSD","pa":"0","ep":"0.00000","cr":"-0.00393000","up":"0","mt":"cross","iw":"0","ps":"BOTH","ma":"BUSD"}],"m":"ORDER"}}}
     2022-01-26 17:35:04:BA.didReceiveMessageWith:{"stream":"znwAi62B0krfvfENOI2zqq5VSOAMU21QGFDAYHxUckgQ3LezOV4Of7RnBbUnDSpo","data":{"e":"ORDER_TRADE_UPDATE","T":1643189704431,"E":1643189704443,"o":{"s":"ETHBUSD","c":"ios_P6GCXs2KGbptudxYR9Wu","S":"SELL","o":"MARKET","f":"GTC","q":"0.003","p":"0","ap":"2486.20000","sp":"0","x":"TRADE","X":"FILLED","i":2845437381,"l":"0.003","z":"0.003","L":"2486.20","n":"0.00171547","N":"BUSD","T":1643189704431,"t":87458210,"b":"0","a":"0","m":false,"R":true,"wt":"CONTRACT_PRICE","ot":"MARKET","ps":"BOTH","cp":false,"rp":"-0.00393000","pP":false,"si":0,"ss":0}}}
     */
}
