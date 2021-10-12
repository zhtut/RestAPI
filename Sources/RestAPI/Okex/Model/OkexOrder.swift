//
//  OkexOrder.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/15.
//

import Foundation

public struct OkexOrder: Codable {
    
    public var instId    : String? ///<     产品ID
    public var ccy    : String? ///<     保证金币种，仅适用于单币种保证金账户下的全仓币币杠杆订单
    public var ordId    : String? ///<     订单ID
    public var clOrdId    : String? ///<     由用户设置的订单ID来识别您的订单
    public var tag    : String? ///<     订单标签
    public var px    : String? ///<     委托价格
    public var sz    : String? ///<     原始委托数量，币币/币币杠杆，以币为单位；交割/永续/期权 ，以张为单位
    public var notionalUsd    : String? ///<     委托单预估美元价值
    public var ordType    : String? ///<     订单类型 market：市价单 limit：限价单 post_only： 只做maker单 fok：全部成交或立即取消单 public ioc：立即成交并取消剩余单 optimal_limit_ioc：市价委托立即成交并取消剩余（仅适用交割、永续）
    public var side    : String? ///<     订单方向，buy sell
    public var posSide    : String? ///<     持仓方向 long：双向持仓多头 short：双向持仓空头 net：单向持仓
    public var tdMode    : String? ///<     交易模式 保证金模式 isolated：逐仓 cross：全仓 非保证金模式 cash：现金
    public var tgtCcy    : String? ///<     委托数量的类型 base_ccy：交易货币 quote_ccy：计价货币
    public var fillPx    : String? ///<     最新成交价格
    public var tradeId    : String? ///<     最新成交ID
    public var fillSz    : String? ///<     最新成交数量
    public var fillTime    : String? ///<     最新成交时间
    public var fillFee    : String? ///<     最新一笔成交的手续费
    public var fillFeeCcy    : String? ///<     最新一笔成交的手续费币种
    public var execType    : String? ///<     最新一笔成交的流动性方向 T：taker M maker
    public var accFillSz    : String? ///<     累计成交数量
    public var fillNotionalUsd    : String? ///<     委托单已成交的美元价值
    public var avgPx    : String? ///<     成交均价，如果成交数量为0，该字段也为0
    public var state    : String? ///<     订单状态 canceled：撤单成功 live：等待成交 partially_filled： 部分成交 filled：完全成交
    public var lever    : String? ///<     杠杆倍数，0.01到125之间的数值，仅适用于 币币杠杆/交割/永续
    public var tpTriggerPx    : String? ///<     止盈触发价
    public var tpOrdPx    : String? ///<     止盈委托价，止盈委托价格为-1时，执行市价止盈
    public var slTriggerPx    : String? ///<     止损触发价
    public var slOrdPx    : String? ///<     止损委托价，止损委托价格为-1时，执行市价止损
    public var feeCcy    : String? ///<     交易手续费币种 币币/币币杠杆：如果是买的话，收取的就是BTC；如果是卖的话，收取的就是USDT public 交割/永续/期权 收取的就是保证金
    public var fee    : String? ///<     订单交易手续费，平台向用户收取的交易手续费
    public var rebateCcy    : String? ///<     返佣金币种 ，如果没有返佣金，该字段为“”
    public var rebate    : String? ///<     返佣金额，平台向达到指定lv交易等级的用户支付的挂单奖励（返佣），如果没有返佣金，该字段为“”
    public var pnl    : String? ///<     收益
    public var category    : String? ///<     订单种类分类 normal：普通委托订单种类 twap：TWAP订单种类 adl：ADL订单种类 public full_liquidation：爆仓订单种类 partial_liquidation：减仓订单种类
    public var uTime    : String? ///<     订单更新时间，Unix时间戳的毫秒数格式，如 1597026383085
    public var cTime    : String? ///<     订单创建时间，Unix时间戳的毫秒数格式，如 1597026383085
    public var reqId    : String? ///<     修改订单时使用的request ID，如果没有修改，该字段为""
    public var amendResult    : String? ///<     修改订单的结果 -1： 失败 0：成功 1：自动撤单（因为修改成功导致订单自动撤销） public 通过API修改订单时，如果cxlOnFail设置为false且修改失败后，则amendResult返回 -1 public 通过API修改订单时，如果cxlOnFail设置为true且修改失败后，则amendResult返回1 public 通过Web/APP修改订单时，如果修改失败后，则amendResult返回-1
    public var code    : String? ///<     错误码，默认为0
    public var msg    : String? ///<     错误消息，默认为""

}
