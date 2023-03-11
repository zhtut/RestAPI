//
//  File.swift
//  
//
//  Created by shutut on 2021/10/12.
//

import Foundation

open class APIKeyConfig {
    public static var `default` = APIKeyConfig()
    // MARK: - Binance
    open var Ba_Api_Key = ""
    open var Ba_Secret_Key = ""
    open var Ba_Base_URL_Str = "https://fapi.binance.com"
    open var BA_Websocket_URL_Str = "wss://fstream.binance.com/ws"
}
