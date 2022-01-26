//
//  File.swift
//  
//
//  Created by shutut on 2022/1/26.
//

import Foundation

public struct BABookTicker: Codable {
    public var e = "" // :"bookTicker",
    public var u = 0 // :1154786566700,
    public var s = "" // :"ETHBUSD",
    public var b = "" // :"2450.03",
    public var B = "" // :"2.346",
    public var a = "" // :"2450.04",
    public var A = "" // :"1.626",
    public var T = 0 // :1643162839528,
    public var E = 0 // :1643162839533
    
    public var center: Double {
        if let ask = a.doubleValue,
           let bid = b.doubleValue {
            return (ask + bid) / 2.0
        }
        return 0.0
    }
}
