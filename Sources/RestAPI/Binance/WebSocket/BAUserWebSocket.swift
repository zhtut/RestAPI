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
    
    var didNoticeReady = false
    open var didReadyBlock: (() -> Void)?
    
    var listenKey: String?
    
    var expiredOrders = [Int]()
    
    open var orders: [BAOrder]?
    open var positions: [BAPosition]?
    open var assets: [BAAsset]?
    
    open var busdBal: Decimal? {
        if let assets = assets {
            for asset in assets {
                if asset.asset == "BUSD" {
                    return asset.marginBalance.decimalValue
                }
            }
        }
        return nil
    }
    
    open override var autoConnect: Bool {
        false
    }
    
    open override var urlStr: String {
        if let listenKey = listenKey {
            let str = "\(APIKeyConfig.default.BA_Websocket_URL_Str)/\(listenKey)"
            return str
        }
        return ""
    }
    
    var putTimer: Timer?
    
    public static let websocketDidReadyNotification = Notification.Name("BAWebsocketDidReadyNotification")
    public static let accountChangedNotification = Notification.Name("BAAccountChangedNotification")
    public static let orderChangedNotification = Notification.Name("BAOrderChangedNotification")
    
    public override init() {
        super.init()
        log("UserWebsocket初始化")
        refreshListenKey()
        
        log("开始刷新订单")
        refreshOrders()
        
        log("开始刷新账户信息")
        refreshAccount()
    }
    
    open func refreshListenKey() {
        log("开始请求ListenKey")
        createListenKey { succ, errMsg in
            if succ {
                self.open()
                
                log("开始刷新ListenKey的有效期")
                self.startPutListenKey()
            } else {
                log("ListenKey请求失败：\(errMsg ?? "")，一秒后重试")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.refreshListenKey()
                }
            }
        }
    }
    
    func createListenKey(completion: @escaping SucceedHandler) {
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
        putTimer?.invalidate()
        putTimer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true, block: { timer in
            self.putListenKey()
        })
    }
    
    func stopPutListenKey() {
        putTimer?.invalidate()
    }
    
    func putListenKey() {
        let path = "PUT /fapi/v1/listenKey (HMAC SHA256)"
        BARestAPI.sendRequestWith(path: path) { response in
            
        }
    }
    
    open override func webSocketDidOpen() {
        super.webSocketDidOpen()
        self.websocketDidReady()
    }
    
    open override func webSocketDidReceive(message: [String: Any]) {
        super.webSocketDidReceive(message: message)
//        log("BA.didReceiveMessageWith:\(message)")
        var data: [String: Any]
        if let _ = message.stringFor("stream"),
           let temp = message["data"] as? [String: Any] {
            data = temp
        } else {
            data = message
        }
        if let e = data.stringFor("e") {
            if e == "listenKeyExpired" {
                refreshListenKey()
                return
            } else if e == "ORDER_TRADE_UPDATE" {
                processOrder(message: message)
                return
            } else if e == "ACCOUNT_UPDATE" {
                processAccount(data: data)
                return
            }
        }
        log("other User websocket message:\(message.jsonStr ?? "")")
    }
    
    func processOrder(message: [String: Any]) {
        log("order变化：\(message.jsonStr ?? "")")
        if let data = message["o"] as? [String: Any] {
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
            guard let ord = data.intFor("i") else { return }
            if self.expiredOrders.contains(ord) {
                return
            }
            order.orderId = ord
            order.executedQty = data.stringFor("z") ?? ""
            order.time = data.intFor("T") ?? 0
            order.workingType = data.stringFor("wt") ?? ""
            order.origType = data.stringFor("ot") ?? ""
            order.positionSide = data.stringFor("ps") ?? ""
            var orders = orders?.filter({
                $0.orderId != order.orderId
            })
            if orders == nil {
                orders = [BAOrder]()
            }
            if order.status == NEW ||
                order.status == PARTIALLY_FILLED {
                orders?.append(order)
            }
            self.orders = orders
            log("有订单发生变化，\(order.price ?? "")\(order.side == BUY ? "买入": "卖出")\(order.origQty ?? "")：\(order.status ?? "")")
            log("当前订单数量：\(self.orders?.count ?? 0)")
            NotificationCenter.default.post(name: BAUserWebSocket.orderChangedNotification, object: order)
            
            // 失效的订单加入一个数组中，五秒后移除
            if order.status == EXPIRED {
                self.expiredOrders.append(ord)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.expiredOrders.remove(ord)
            }
        } else {
            fatalError("order没有op字段")
        }
    }
    
    func websocketDidReady() {
        if self.didNoticeReady {
            return
        }
        guard let _ = self.orders else {
            return
        }
        guard let _ = self.positions else {
            return
        }
        guard self.isConnected else {
            return
        }
        if let didReadyBlock = didReadyBlock {
            didReadyBlock()
        }
        NotificationCenter.default.post(name: BAUserWebSocket.websocketDidReadyNotification, object: nil)
        self.didNoticeReady = true
    }
    
    open func refreshOrders() {
        fetchPendingOrders { orders, errMsg in
            if let orders = orders {
                self.orders = orders
                log("已刷新，当前订单数量：\(self.orders?.count ?? 0)")
                self.websocketDidReady()
            } else {
                log("刷新订单失败")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.refreshOrders()
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
    
    func processAccount(data: [String: Any]) {
        if let a = data["a"] as? [String: Any] {
            if let B = a["B"] as? [[String: Any]] {
                for b in B {
                    let sym = b.stringFor("a")
                    for asset in assets ?? [BAAsset]() {
                        if sym == asset.asset {
                            asset.walletBalance = b.stringFor("wb") ?? ""
                            asset.crossWalletBalance = b.stringFor("cw") ?? ""
                            if let bc = b.stringFor("bc")?.doubleValue,
                            let total = asset.walletBalance.doubleValue {
                                let avail = bc + total
                                asset.availableBalance = "\(avail)"
                            }
                            break
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
                        newPosition.symbol = s
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
                self.websocketDidReady()
            } else {
                log("刷新Account失败：\(response.errMsg ?? "")")
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
