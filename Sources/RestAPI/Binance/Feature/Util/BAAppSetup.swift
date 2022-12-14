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
    
    open var instId = "ETHBUSD"

    open var instrument: Instrument!
    
    open func setup(instId: String) async throws {
        log("setup App方法，开始app")
        
        sendPushNotication("开始记录日志")
        let _ = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { timer in
            sendPushNotication("状态消息，当前状态正常")
        }
        
        let _ = BAPosManager.shared
        
        self.instId = instId
        
        let bookTickerManger = BABookTickerManger.shared
        bookTickerManger.instId = instId
        bookTickerManger.subcribeDepth()
        
        log("开始请求产品信息")
        do {
            try await requestInstrument()
            log("请求产品信息成功，初始化完成")
            guard let _ = self.instrument else {
                throw CommonError(errMsg: "没有找到instrument")
            }
            let websocket = BAFAccountWebSocket.shared
            return await withCheckedContinuation { continuation in
                websocket.didReadyBlock = {
                    BAPosManager.shared.configLever()
                    continuation.resume()
                }
            }
        } catch {
            log("请求产品信息失败：\(error)，程序退出")
        }
    }
    
    open func requestInstrument() async throws {
        let path = "GET /fapi/v1/exchangeInfo"
        let response = await BARestAPI.sendRequestWith(path: path, dataKey: "symbols")
        if response.responseSucceed {
            guard let arr = response.data as? [[String: Any]] else {
                throw CommonError(errMsg: "BAInstrument返回格式有问题")
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
                    return
                }
            }
        }
        
        throw CommonError(errMsg: response.errMsg ?? "")
    }
}
