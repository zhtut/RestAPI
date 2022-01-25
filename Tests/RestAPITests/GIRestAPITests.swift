//
//  File.swift
//  
//
//  Created by shutut on 2022/1/25.
//

import XCTest
@testable import RestAPI

class GIRestAPITests: XCTestCase {
    
    func testGIRestAPI() {
        let semaphore = DispatchSemaphore(value: 1)
        
        semaphore.wait(timeout: .distantFuture)
    }
    
}
