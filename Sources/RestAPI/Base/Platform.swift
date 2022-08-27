//
//  File.swift
//  
//
//  Created by shutut on 2021/10/31.
//

import Foundation
import SSLog

/// 平台
public enum Platform: String {
    case Okex
    case Huobi
    case Binance
    case GateIO
    
    /// 附加平台在前面的日志输出
    /// - Parameter message: 原始日志
    func log(_ message: String) {
        let str = "\(self): \(message)"
        SSLogManager.shared.log(str)
    }
}

/// 平台基类
open class PlatformBase: NSObject {
    
    /// 平台
    open var platform = Platform.Binance
    
    /// 附加平台在前面的日志输出
    /// - Parameter message: 原始日志
    open func log(_ message: String) {
        platform.log(message)
    }
}
