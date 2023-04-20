//
//  ATCmdHelper.swift
//  Basic Chat MVC
//
//  Created by wu hsin-hsien on 2023/4/14.
//

import Foundation

import UIKit
import DequeModule

//ATCmd處理 主要用Delegate，特殊情況才考慮用Notifaction

enum ATCmdSendCommand : String, CaseIterable {
    case GBAT = "AT+GBAT"
    case GGPS = "AT+GGPS"
    case GTIME = "AT+GTIME"
    case GVER = "AT+GVER"
    //case GLOG =
    //case SUID =
    case SVOICE = "AT+SVOICE"
    //case SUGENT =
    case NotSet = "ATCmd NotSet"
}

enum ATCmdReceiveHeader : UInt16, CaseIterable {
    case GBAT = 0x0274
    case GGPS = 0x0288
    case GTIME = 0x0501
    case GVER = 0x0502
    //case GLOG =
    //case SUID =
    //case SVOICE =
    //case SUGENT =
    case NotFound = 0xffff
    case NotSet = 0x0000
}

enum ATCmdReceiveDataKey : String {
    case BatteryLV = "BatteryLV"
    case Latitude = "Latitude"
    case Longitude = "Longitude"
    case UTCDate = "UTCDate"
    case HWVer = "HWVer"
}

struct ATCmdReceiveData {
    var cmdCode: ATCmdReceiveHeader
    var dataAry: [ATCmdReceiveDataKey: String]
}

//TODO: 建立AT指令 與 處理回傳資料 與 Queue，指令送出由DeviceMagHelper處理

class ATCmdHelper: NSObject {
    static let shared = ATCmdHelper()
    
    public static let CMDCodeStrLength: Int = 4
    public static let CMDReceiveOneTimeEndStr: String = "\nOK".lowercased()
    public static let CMDReceiveBatchFinishStr: String = "\nEOF".lowercased() //批次傳輸後面無資料
    public static let CMDReceiveBatchContinueStr: String = "\nTBC".lowercased() //批次傳輸後面還有資料，要再呼叫CMD抓
    public static let LocationDegreesFixedDivisor: Double = 10000000.0 //座標固定格式 用INT代表 正負1~3位整數部分 + 小數點固定後七位
    
    public static let CMDSendRetryTimes: Int = 3 //送出出錯時 重試幾次
    public static let CMDSendRetryDelay: TimeInterval = 0.1 //送出出錯時 延遲多少秒重試
    
    var ATCmdDeque: Deque<ATCmdData> = []
    
    public static func receiveToData(_ receive: String?) -> ATCmdReceiveData? {
        print("receiveToData:", receive ?? "nil")
        if var procStr = receive {
            if !procStr.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix(CMDReceiveOneTimeEndStr) {
                print("No CMD End")
                return nil
            } else {
                procStr = procStr.trimmingCharacters(in: .whitespacesAndNewlines)
                let endIndex = procStr.index(procStr.endIndex, offsetBy:-CMDReceiveOneTimeEndStr.count)
                procStr = String(procStr[...endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            var findCmdCode: ATCmdReceiveHeader? = nil
            for code in ATCmdReceiveHeader.allCases {
                let cmdHexStr = ATCmdHelper.receiveCodeToHexString(code)
                if procStr.hasPrefix(cmdHexStr) {
                    findCmdCode = code
                    print("Find CMD:", code, "("+cmdHexStr+")")
                    break
                }
            }
            
            if let procCmdCode = findCmdCode {
                var procSuccess = false
                var receiveData: [ATCmdReceiveDataKey: String] = [:]
                let startIndex = procStr.index(procStr.startIndex, offsetBy:ATCmdHelper.CMDCodeStrLength)
                let payload: String = String(procStr[startIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
                switch procCmdCode {
                    case .GBAT:
                        if !payload.isEmpty {
                            receiveData[ATCmdReceiveDataKey.BatteryLV] = payload
                            procSuccess = true
                        }
                        break
                    case .GGPS:
                        break
                    case .GTIME:
                        break
                    case.GVER:
                        break
                    case .NotFound:
                        break
                    case .NotSet:
                        break
                }
                
                if procSuccess {
                    return ATCmdReceiveData(cmdCode: procCmdCode, dataAry: receiveData)
                } else {
                    print("Process Payload Not success")
                }
            } else {
                print("No match CMD")
            }
        }
        
        return nil
    }
    
    public static func receiveCodeToHexString(_ code: ATCmdReceiveHeader) -> String{
        let str = String(format:"%04X", code.rawValue)
        return str
    }
    
    public static func hexStringToFloat(_ hexString: String?) -> Float? {
        if let hexStr = hexString {
            //Str先轉成I32
            if let toInt = self.hexStringToInt32(hexStr) {
                //把Int32位元資料當成Float來轉換
                let toFloat = Float(bitPattern: UInt32(toInt))
                return toFloat
            }
        }
        return nil
    }
    
    public static func hexStringToLocationDegrees(_ hexString: String?) -> Double? {
        if let hexStr = hexString {
            //Str先轉成I32
            if let toInt = self.hexStringToInt32(hexStr) {
                //把Int32位元資料當成Float來轉換
                let toDouble: Double = Double(toInt) / self.LocationDegreesFixedDivisor
                return toDouble
            }
        }
        return nil
    }
    
    public static func hexStringToInt32(_ hexString: String?) -> Int? {
        if let hexStr = hexString {
            return strtol(hexStr, nil, 16)
        }
        return nil
    }
}
