//
//  File.swift
//
//
//  Created by shutut on 2021/11/27.
//

import Foundation
import SSLog
import SSCommon

open class BAAppSetup {
    
    public static let shared = BAAppSetup()
    
    open var instId = ""

    open var instrument: Instrument!
    open var completion: SucceedHandler?
    
    open func setup(instId: String, completion: @escaping SucceedHandler) {
        log("setup App方法，开始app")
        
        sendPushNotication("开始记录日志")
        let _ = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { timer in
            sendPushNotication("状态消息，当前状态正常")
        }
        
        let _ = BAPosManager.shared
        
        self.instId = instId
        self.completion = completion
        
        let bookTickerManger = BABookTickerManger.shared
        bookTickerManger.instId = instId
        bookTickerManger.subcribeDepth()
        
        log("开始请求产品信息")
        requestInstrument { succ, errMsg in
            if succ {
                log("请求产品信息成功，初始化完成")
                guard let _ = self.instrument else {
                    log("请求产品信息失败：\(errMsg ?? "")，程序退出")
                    exit(1)
                }
                let websocket = BAUserWebSocket.shared
                websocket.didReadyBlock = {
                    BAPosManager.shared.configLever()
                    self.completion?(true, nil)
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
                        /// 下单最小值
                        instrument.minSz = ins.minSz ?? ""
                        self.instrument = instrument
                        completion(true, nil)
                        return
                    }
                }
            }
            
            completion(false, response.errMsg)
        }
    }
}
