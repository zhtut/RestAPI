//
//  HBSymbol.swift
//  SmartCurrency
//
//  Created by shutut on 2021/8/17.
//

import Foundation

class HBSymbol: Codable {
    var base_currency: String? ///<    true    string    交易对中的基础币种
    var quote_currency: String? ///<    true    string    交易对中的报价币种
    var symbol: String? ///<    true    string    交易对
    var state: String? ///<    true    string    交易对状态；可能值: [online，offline,suspend] online _ 已上线；offline _ 交易对已下线，不可交易；suspend __ 交易暂停；pre_online _ 即将上线
    var api_trading: String? ///<    true    string    API交易使能标记（有效值：enabled, disabled）
    var price_precision: Int? ///<    true    integer 交易对报价的精度（小数点后位数），限价买入与限价卖出价格使用
    var value_precision: Int? ///<    true    integer    交易对交易金额的精度（小数点后位数），市价买入金额使用
    var amount_precision: Int? ///<    true    integer    交易对基础币种计数精度（小数点后位数），限价买入、限价卖出、市价卖出数量使用
    var sell_market_min_order_amt: Double? ///<    true    float    交易对市价卖单最小下单量，以基础币种为单位（NEW）
    //    var symbol_partition: String? ///<    true    string    交易区，可能值: [main，innovation]
    //    var min_order_amt: String? ///<    true    float    交易对限价单最小下单量 ，以基础币种为单位（即将废弃）
    //    var limit_order_min_order_amt: String? ///<    true    float    交易对限价单最小下单量 ，以基础币种为单位（NEW）
//    var min_order_value: String? ///<    true    float    交易对限价单和市价买单最小下单金额 ，以计价币种为单位
//    var leverage_ratio: String? ///<    true    float    交易对杠杆最大倍数(仅对逐仓杠杆交易对、全仓杠杆交易对、杠杆ETP交易对有效）
//    var underlying: String? ///<    false    string    标的交易代码 (仅对杠杆ETP交易对有效)
//    var mgmt_fee_rate: String? ///<    false    float    持仓管理费费率 (仅对杠杆ETP交易对有效)
//    var charge_time: String? ///<    false    string    持仓管理费收取时间 (24小时制，GMT+8，格式：HH:MM:SS，仅对杠杆ETP交易对有效)
//    var rebal_time: String? ///<    false    string    每日调仓时间 (24小时制，GMT+8，格式：HH:MM:SS，仅对杠杆ETP交易对有效)
//    var rebal_threshold: String? ///<    false    float    临时调仓阈值 (以实际杠杆率计，仅对杠杆ETP交易对有效)
//    var init_nav: String? ///<    false    float    初始净值（仅对杠杆ETP交易对有效）
    /*
    "amount-precision" = 4;
    "api-trading" = enabled;
    "base-currency" = eth;
    "buy-market-max-order-value" = 1000000;
    "leverage-ratio" = 5;
    "limit-order-max-buy-amt" = 10000;
    "limit-order-max-order-amt" = 10000;
    "limit-order-max-sell-amt" = 10000;
    "limit-order-min-order-amt" = "0.001";
    "max-order-amt" = 10000;
    "min-order-amt" = "0.001";
    "min-order-value" = 5;
    "price-precision" = 2;
    "quote-currency" = usdt;
    "sell-market-max-order-amt" = 1000;
    "sell-market-min-order-amt" = "0.001";
    state = online;
    "super-margin-leverage-ratio" = 3;
    symbol = ethusdt;
    "symbol-partition" = main;
    tags = "";
    "value-precision" = 8;
 */
}
