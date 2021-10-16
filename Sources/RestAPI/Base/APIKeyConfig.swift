//
//  File.swift
//  
//
//  Created by shutut on 2021/10/12.
//

import Foundation

open class APIKeyConfig {
    public static var `default` = APIKeyConfig()
    
    open var OKex_API_KEY = ""
    open var OKex_SECRET_KEY = ""
    open var OKex_Passphrase = ""
    open var Okex_BaseURL = "https://aws.okex.com"
    open var Okex_WebsocketPublicURL = "wss://wsaws.okex.com:8443/ws/v5/public"
    open var Okex_WebsocketPrivateURL = "wss://wsaws.okex.com:8443/ws/v5/private"
}
