//
//  File.swift
//
//
//  Created by shutut on 2021/11/27.
//

import Foundation
import SSLog
import SSCommon

open class BASetup {
    
    public static let shared = BASetup()
    
    open var instId = "ETHBUSD"

    open var instrument: Instrument?
    open var completion: SucceedHandler?
    
    open var bookTickerManger = BABookTickerManger.shared
    open var posManager = BAPosManager.shared
    
    public init() {
        log("init方法，开始app")
        setup()
    }
    
    open func setup() {
        let _ = BAUserWebSocket.shared
        
        bookTickerManger.instId = instId
        bookTickerManger.subcribeDepth()
        
        posManager.bookTickerManger = bookTickerManger
        
        log("开始请求产品信息")
        requestInstrument { succ, errMsg in
            if succ {
                log("请求产品信息成功，开始取消所有订单")
                self.posManager.instrument = self.instrument
                self.cancelAllOrders { succ, errMsg in
                    if succ {
                        log("取消所有订单成功，初始化完成")
                        self.completion?(true, nil)
                    } else {
                        log("取消所有订单失败：\(errMsg ?? "")，程序退出")
                        exit(1)
                    }
                }
            } else {
                log("请求产品信息失败：\(errMsg ?? "")，程序退出")
                exit(1)
            }
        }
    }
    
    open func requestInstrument(completion: @escaping SucceedHandler) {
        let path = "GET /fapi/v1/exchangeInfo"
        BARestAPI.sendRequestWith(path: path, dataKey: "symbols") { response in
            if response.responseSucceed {
                guard let arr = response.data as? [[String: Any]] else {
                    completion(false, "BAInstrument返回格式有问题")
                    return
                }
                for dic in arr {
                    let ins = BAInstrument.modelWith(dic: dic)
                    if ins.symbol == self.instId {
                        var instrument = Instrument()
                        instrument.instId = ins.symbol ?? "" /// : String?
                        /// 交易货币币种，如 BTC-USDT 中BTC ，仅适用于币币
                        instrument.baseCcy = ins.baseAsset ?? "" ///: String?
                        /// 计价货币币种，如 BTC-USDT 中 USDT ，仅适用于币币
                        instrument.quoteCcy = ins.quoteAsset ?? "" /// : String?
                        /// 下单价格精度，如 0.0001
                        instrument.tickSz = ins.tickSz ?? "" ///: String?
                        /// 下单数量精度，如 1：BTC-USDT-200925 0.001：BTC-USDT
                        instrument.lotSz = ins.lotSz ?? "" /// : String?
                        self.instrument = instrument
                        completion(true, nil)
                        return
                    }
                }
            }
            
            completion(false, response.errMsg)
        }
    }
    
    open func cancelAllOrders(completion: @escaping SucceedHandler) {
        BAOrder.cancelAllOrders(symbol: instId, completion: completion)
    }
}
