//
//  BAFAccountWebSocket.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/23.
//

import Foundation
import SSCommon
import SSLog

open class BAFAccountWebSocket: BAWebSocket {
    
    public static let shared = BAFAccountWebSocket()
    
    var didNoticeReady = false
    open var didReadyBlock: (() -> Void)?
    
    var listenKey: String?
    
    var expiredOrders = [Int]()
    
    open var orders: [BAFOrder]?
    open var positions: [BAFPosition]?
    open var assets: [BAFAsset]?
    
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
        Task {
            await self.refreshListenKey()
            
            log("开始刷新订单")
            await refreshOrders()
            
            log("开始刷新账户信息")
            await refreshAccount()
        }
    }
    
    open func refreshListenKey() async {
        log("开始请求ListenKey")
        let result = await createListenKey()
        if result.succ {
            log("ListenKey请求成功，开始连接")
            self.open()
            
            log("开始刷新ListenKey的有效期")
            self.startPutListenKey()
        } else {
            log("ListenKey请求失败：\(result.errMsg ?? "")，一秒后重试")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                Task {
                   await self.refreshListenKey()
                }
            }
        }
    }
    
    func createListenKey() async -> (succ: Bool, errMsg: String?) {
        let path = "POST /fapi/v1/listenKey (HMAC SHA256)"
        let response = await BARestAPI.sendRequestWith(path: path)
        if response.responseSucceed {
            if let data = response.data as? [String: Any],
               let listenKey = data.stringFor("listenKey") {
                self.listenKey = listenKey
                log("请求listenKey成功：\(listenKey)")
                return (true, nil)
            }
        }
        return (false, response.errMsg)
    }
    
    func startPutListenKey() {
        putTimer?.invalidate()
        putTimer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true, block: { timer in
            Task {
                await self.putListenKey()
            }
        })
    }
    
    func stopPutListenKey() {
        putTimer?.invalidate()
    }
    
    func putListenKey() async {
        let path = "PUT /fapi/v1/listenKey (HMAC SHA256)"
        await BARestAPI.sendRequestWith(path: path)
    }
    
    open override func webSocketDidOpen() {
        super.webSocketDidOpen()
        self.websocketDidReady()
        log("accountwebSocketDidOpen")
    }
    
    open override func webSocketDidReceive(message: [String: Any]) {
        super.webSocketDidReceive(message: message)
//        log("BA.didReceiveMessageWith:\(message.jsonStr ?? "")")
        var data: [String: Any]
        if let _ = message.stringFor("stream"),
           let temp = message["data"] as? [String: Any] {
            data = temp
        } else {
            data = message
        }
        if let e = data.stringFor("e") {
            if e == "listenKeyExpired" {
                Task {
                    await refreshListenKey()
                }
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
        if let data = message["o"] as? [String: Any] {
            let order = BAFOrder()
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
                orders = [BAFOrder]()
            }
            if order.status == NEW ||
                order.status == PARTIALLY_FILLED {
                orders?.append(order)
            }
            self.orders = orders
            let price = order.price?.intValue ?? 0
            let action = order.side == BUY ? "买入": "卖出"
            let qty = order.origQty ?? ""
            log("订单变化: \(price > 0 ? "\(price)" : "市价")\(action)\(qty), 状态: \(order.status ?? "")")
            log("当前订单数量：\(self.orders?.count ?? 0)")
            NotificationCenter.default.post(name: BAFAccountWebSocket.orderChangedNotification, object: order)
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
        guard self.websocket?.state == .connected else {
            return
        }
        if let didReadyBlock = didReadyBlock {
            didReadyBlock()
        }
        NotificationCenter.default.post(name: BAFAccountWebSocket.websocketDidReadyNotification, object: nil)
        self.didNoticeReady = true
    }
    
    open func refreshOrders() async {
        let orderResult = await fetchPendingOrders()
        if let orders = orderResult.0 {
            self.orders = orders
            self.websocketDidReady()
        } else {
            log("刷新订单失败")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            Task {
               await self.refreshOrders()
            }
        }
    }
    
    func fetchPendingOrders() async -> ([BAFOrder]?, String?) {
        let path = "GET /fapi/v1/openOrders (HMAC SHA256)"
        let response = await BARestAPI.sendRequestWith(path: path, dataClass: BAFOrder.self)
        if let data = response.data as? [BAFOrder] {
            return (data, nil)
        } else {
            return (nil, response.errMsg)
        }
    }
    
    func processAccount(data: [String: Any]) {
        if let a = data["a"] as? [String: Any] {
            if let B = a["B"] as? [[String: Any]] {
                for b in B {
                    let sym = b.stringFor("a")
                    for asset in assets ?? [BAFAsset]() {
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
                    var find: BAFPosition?
                    for position in positions ?? [BAFPosition]() {
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
                        let newPosition = BAFPosition()
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
        NotificationCenter.default.post(name: BAFAccountWebSocket.accountChangedNotification, object: nil)
    }
    
    open func refreshAccount() async {
        let path = "GET /fapi/v2/account (HMAC SHA256)"
        let response = await BARestAPI.sendRequestWith(path: path)
        if let data = response.data as? [String: Any] {
            if let positions = data["positions"] as? [[String: Any]],
               let models = positions.transformToModelArray(BAFPosition.self) {
                let avail = models.filter { position in
                    position.positionAmt.doubleValue! != 0.0
                }
                self.positions = avail
            } else {
                self.positions = [BAFPosition]()
            }
            if let assets = data["assets"] as? [[String: Any]],
               let models = assets.transformToModelArray(BAFAsset.self) {
                self.assets = models
            } else {
                self.assets = [BAFAsset]()
            }
            self.websocketDidReady()
        } else {
            log("刷新Account失败：\(response.errMsg ?? "")")
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
