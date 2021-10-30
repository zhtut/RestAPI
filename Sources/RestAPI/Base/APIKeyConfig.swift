//
//  File.swift
//  
//
//  Created by shutut on 2021/10/12.
//

import Foundation

open class APIKeyConfig {
    public static var `default` = APIKeyConfig()
    
    // MARK: - Okex
    
    open var OK_API_KEY = ""
    open var OK_SECRET_KEY = ""
    open var OK_Passphrase = ""
    open var OK_BaseURL = "https://aws.okex.com"
    open var OK_WebsocketPublicURL = "wss://wsaws.okex.com:8443/ws/v5/public"
    open var OK_WebsocketPrivateURL = "wss://wsaws.okex.com:8443/ws/v5/private"
    
    // MARK: - Huobi
    
    open var HB_Access_Key = ""
    open var HB_Secret_Key = ""
    
    open var HB_Spot_BaseURL = "https://api-aws.huobi.pro"
    open var HB_Spot_Websocket_MarketURL = "wss://api-aws.huobi.pro/ws"
    open var HB_Spot_Websocket_UserURL = "wss://api-aws.huobi.pro/ws/v2"
    
    open var HB_Swap_BaseURL = "https://api.hbdm.vn"
    // 合约站行情请求以及订阅地址为：
    open var HB_Swap_Websocket_MarketURL = "wss://api.hbdm.vn/linear-swap-ws"
    
    // 合约站订单推送订阅地址：
    open var HB_Swap_Websocket_OrderURL = "wss://api.hbdm.vn/linear-swap-notification"
  
    // 合约站指数K线及基差数据订阅地址：
    open var HB_Swap_Websocket_CandleURL = "wss://api.hbdm.vn/ws_index"
    
    // 合约站系统状态更新订阅地址：
    open var HB_Swap_Websocket_SystemURL = "wss://api.hbdm.vn/center-notification"
    
    // MARK: - Binance
    
    open var Ba_Api_Key = ""
    open var Ba_Secret_Key = ""
    open var Ba_Base_URL_Str = "https://api.binance.com"
}
