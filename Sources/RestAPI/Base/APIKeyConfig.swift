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
    
    // MARK: - Binance
    
    open var Ba_Api_Key = ""
    open var Ba_Secret_Key = ""
    open var Ba_Base_URL_Str = "https://api.binance.com"
    
    // MARK: - GateIO
    
    open var GI_Api_Key = ""
    open var GI_Secret_Key = ""
    open var GI_Base_URL_Str = "https://api.gateio.ws/api/v4"
}
