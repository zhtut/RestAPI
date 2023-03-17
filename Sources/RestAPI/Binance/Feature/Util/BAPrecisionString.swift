//
//  File.swift
//  
//
//  Created by zhtg on 2023/3/17.
//

import Foundation

public extension Double {
    var precision: Decimal {
        let str = self.precisionStringWith(precision: BAFAppSetup.shared.instrument.tickSz)
        return Decimal(string: str) ?? 0
    }
}

public extension Decimal {
    var precision: Decimal {
        let str = self.precisionStringWith(precision: BAFAppSetup.shared.instrument.tickSz)
        return Decimal(string: str) ?? 0
    }
}
