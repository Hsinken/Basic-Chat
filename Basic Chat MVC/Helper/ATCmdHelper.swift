//
//  ATCmdHelper.swift
//  Basic Chat MVC
//
//  Created by wu hsin-hsien on 2023/4/14.
//

import Foundation

import UIKit

enum ATCmdReceiveCode : UInt16, CaseIterable {
    case GBAT = 0x0274
    case GGPS = 0x0288
    case GTIME = 0x0501
    case GVER = 0x0502
    //case GLOG =
    //case SUID =
    //case SVOICE =
    //case SUGENT =
    case NotFound = 0xffff
}

enum ATCmdReceiveDataKey : String {
    case BatteryLV = "BatteryLV"
    case Latitude = "Latitude"
    case Longitude = "Longitude"
    case UTCDate = "UTCDate"
    case HWVer = "HWVer"
}

struct ATCmdReceiveData {
    var cmdCode: ATCmdReceiveCode
    var dataAry: [ATCmdReceiveDataKey: String]
}

//TODO: 建立AT指令 與 處理回傳資料，送指令由DeviceMagHelper處理

class ATCmdHelper: NSObject {
    public static let CMDCodeStrLength: Int = 4
    public static let EndCMDStr: String = "\nOK".lowercased()
    public static let LocationDegreesFixedDivisor: Double = 10000000.0 //座標固定格式 用INT代表 正負1~3位整數部分 + 小數點固定後七位
    
    public static func receiveToData(_ receive: String?) -> ATCmdReceiveData? {
        print("receiveToData:", receive ?? "nil")
        if var procStr = receive {
            if !procStr.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix(EndCMDStr) {
                print("No CMD End")
                return nil
            } else {
                procStr = procStr.trimmingCharacters(in: .whitespacesAndNewlines)
                let endIndex = procStr.index(procStr.endIndex, offsetBy:-EndCMDStr.count)
                procStr = String(procStr[...endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            var findCmdCode: ATCmdReceiveCode? = nil
            for code in ATCmdReceiveCode.allCases {
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
    
    public static func receiveCodeToHexString(_ code: ATCmdReceiveCode) -> String{
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