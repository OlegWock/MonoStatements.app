//
//  MonoAPI.swift
//  MonoStatements
//
//  Created by Oleh Korniienko on 02.05.2021.
//

import Foundation

typealias MonoAPICallback<T> = (_ result: T?, _ error: Bool) -> Void



enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
    case OPTIONS
    case HEAD
    
}


class MonoAPI {
    let baseUrl = URL(string: "https://api.monobank.ua")
    let apiKey: String
    
    var exchangesCache: [ExchangeRate] = []
    var exchangesCachePulledAt: Date = Date.distantPast
    
    init(apiKey: String) {
        self.apiKey = apiKey;
    }
    
    private func makeRequest<T: Decodable>(method: HTTPMethod, relativeUrl: String, data: Data?,
                                           onComplete: @escaping MonoAPICallback<T>) {
        let absoluteUrl = URL(string: relativeUrl, relativeTo: baseUrl)
        var request = URLRequest(url: absoluteUrl!)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Token")
        request.timeoutInterval = 20
        request.httpBody = data
    
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do {
//                    print(String(decoding: data, as: UTF8.self))
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    let json = try decoder.decode(T.self, from: data)
                    onComplete(json, false)
                } catch {
                    print(error)
                    onComplete(nil, true)
                }
            }
        }.resume()
        
    }
    
    private func makeRequest<T: Decodable>(method: HTTPMethod, relativeUrl: String,
                                           onComplete: @escaping MonoAPICallback<T>) {
        self.makeRequest(method: method, relativeUrl: relativeUrl, data: nil, onComplete: onComplete)
    }
    
    func getUserInfo(onComplete: @escaping MonoAPICallback<UserInfo>) {
        self.makeRequest(method: .GET, relativeUrl: "/personal/client-info", onComplete: onComplete)
    }
    
    func getStatements(account: String, from: Date, to: Date, onComplete: @escaping MonoAPICallback<[Statement]>) {
        let fromTimestamp = Int.init(from.timeIntervalSince1970)
        let toTimestamp = Int.init(to.timeIntervalSince1970)
        self.makeRequest(method: .GET,
                         relativeUrl: "/personal/statement/\(account)/\(fromTimestamp)/\(toTimestamp)",
                         onComplete: onComplete)
    }
    
    func getStatements(account: String, from: Date, onComplete: @escaping MonoAPICallback<[Statement]>) {
        self.getStatements(account: account, from: from, to: Date.init(), onComplete: onComplete)
    }
    
    func getExchangeRates(onComplete: @escaping MonoAPICallback<[ExchangeRate]>) {
        self.makeRequest(method: .GET, relativeUrl: "/bank/currency") { (rates: [ExchangeRate]?, error) in
            if !error {
                self.exchangesCache = rates!
                self.exchangesCachePulledAt = Date.init()
            }
            onComplete(rates, error)
        }
    }
    
    func convertCurrency(amount: LowestCurrencyDenomination,
                         from: CurrencyCode, to: CurrencyCode) -> LowestCurrencyDenomination {
        var multiplier: Double = 1.0
        for rate in exchangesCache {
            if rate.currencyCodeA == from || rate.currencyCodeB == from{
                if rate.rateCross != nil {
                    multiplier = rate.rateCross!
                } else if rate.rateBuy != nil && rate.rateSell != nil {
                    multiplier = (rate.rateBuy! + rate.rateSell!) / 2
                }
                
                if rate.currencyCodeA == from {
                    multiplier = 1 / multiplier
                }
                break
            }
        }
        
        return Int(Double(amount) / multiplier)
    }
    
}

typealias LowestCurrencyDenomination = Int // Cents, eurocents, kopek etc

enum CurrencyCode: Int, Codable {
    case AUD = 036
    case EUR = 978
    case AZN = 944
    case ALL = 008
    case DZD = 012
    case AOA = 973
    case XCD = 951
    case ARS = 032
    case AWG = 533
    case AFN = 971
    case BSD = 044
    case BDT = 050
    case BBD = 052
    case BHD = 048
    case BZD = 084
    case XOF = 952
    case BMD = 060
    case BYN = 933
    case BGN = 975
    case BOB = 068
    case BOV = 984
    case USD = 840
    case BAM = 977
    case BWP = 072
    case BRL = 986
    case GBP = 826
    case BND = 096
    case BIF = 108
    case INR = 356
    case BTN = 064
    case VUV = 548
    case VEF = 937
    case VND = 704
    case AMD = 051
    case XAF = 950
    case HTG = 332
    case GYD = 328
    case GMD = 270
    case GHS = 936
    case GNF = 324
    case HNL = 340
    case HKD = 344
    case GEL = 981
    case GTQ = 320
    case GIP = 292
    case DKK = 208
    case DJF = 262
    case DOP = 214
    case ERN = 232
    case ETB = 230
    case EGP = 818
    case XSU = 994
    case YER = 886
    case ZMW = 967
    case MAD = 504
    case ZWL = 932
    case ILS = 376
    case IDR = 360
    case IQD = 368
    case IRR = 364
    case ISK = 352
    case JOD = 400
    case CVE = 132
    case KZT = 398
    case KYD = 136
    case KHR = 116
    case CAD = 124
    case QAR = 634
    case KES = 404
    case KGS = 417
    case CNY = 156
    case COP = 170
    case COU = 970
    case KMF = 174
    case CDF = 976
    case KPW = 408
    case KRW = 410
    case CRC = 188
    case XUA = 965
    case CUP = 192
    case CUC = 931
    case KWD = 414
    case ANG = 532
    case LAK = 418
    case LSL = 426
    case ZAR = 710
    case LRD = 430
    case LBP = 422
    case LYD = 434
    case CHF = 756
    case MRO = 478
    case MUR = 480
    case MGA = 969
    case MOP = 446
    case MKD = 807
    case MWK = 454
    case MYR = 458
    case MVR = 462
    case MXN = 484
    case MXV = 979
    case XDR = 960
    case MZN = 943
    case MDL = 498
    case MNT = 496
    case MMK = 104
    case NAD = 516
    case NPR = 524
    case NGN = 566
    case NIO = 558
    case NZD = 554
    case XPF = 953
    case NOK = 578
    case AED = 784
    case OMR = 512
    case SHP = 654
    case PKR = 586
    case PAB = 590
    case PGK = 598
    case PYG = 600
    case PEN = 604
    case SSP = 728
    case PLN = 985
    case RUB = 643
    case RWF = 646
    case RON = 946
    case SVC = 222
    case WST = 882
    case STD = 678
    case SAR = 682
    case SZL = 748
    case SCR = 690
    case RSD = 941
    case SYP = 760
    case SGD = 702
    case SBD = 090
    case SOS = 706
    case SDG = 938
    case SRD = 968
    case USN = 997
    case SLL = 694
    case TJS = 972
    case THB = 764
    case TWD = 901
    case TZS = 834
    case TOP = 776
    case TTD = 780
    case TND = 788
    case TRY = 949
    case TMT = 795
    case UGX = 800
    case HUF = 348
    case UZS = 860
    case UAH = 980
    case UYU = 858
    case UYI = 940
    case FJD = 242
    case PHP = 608
    case FKP = 238
    case HRK = 191
    case CZK = 203
    case CLP = 152
    case CLF = 990
    case CHE = 947
    case CHW = 948
    case SEK = 752
    case LKR = 144
    case JMD = 388
    case JPY = 392
    case XBA = 955
    case XBB = 956
    case XBC = 957
    case XBD = 958
    case XTS = 963
    case XXX = 999
    case XAU = 959
    case XPD = 964
    case XPT = 962
    case XAG = 961
    case ZMK = 894
}

enum AccountType: String, Codable {
    case black
    case white
    case platinum
    case iron
    case fop
    case yellow
}

enum CashbackType: String, Codable {
    case none = ""
    case UAH
    case miles = "Miles"
}

struct UserInfo: Decodable {
    let clientId: String
    let name: String
    let webHookUrl: String
    let accounts: [Account]
}

struct Account: Decodable {
    let id: String
    let balance: LowestCurrencyDenomination
    let creditLimit: LowestCurrencyDenomination
    let type: AccountType
    let currencyCode: CurrencyCode
    let cashbackType: CashbackType
}

struct Statement: Decodable {
    let id: String
    let time: Date
    let description: String
    let mcc: Int
    let originalMcc: Int?
    let hold: Bool
    let amount: LowestCurrencyDenomination // Amount in account currency
    let operationAmount: LowestCurrencyDenomination // Amount in original transaction's currency
    let currencyCode: CurrencyCode
    let commissionRate: LowestCurrencyDenomination
    let balance: LowestCurrencyDenomination
    let comment: String?
    let receiptId: String?
    let counterEdrpou: String?
    let counterIban: String?
}

struct ExchangeRate: Decodable {
    let currencyCodeA: CurrencyCode
    let currencyCodeB: CurrencyCode
    let date: Date
    let rateSell: Double?
    let rateBuy: Double?
    let rateCross: Double?
}
