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

struct ATCmdReceiveData {
    var command: ATCommand
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
            
            var findCmd: ATCommand? = nil
            for cmd in ATCommand.allCases {
                if procStr.hasPrefix(cmd.rawValue.recvHeaderStr) {
                    findCmd = cmd
                    print("Find CMD:", cmd)
                    break
                }
            }
            
            if let procCmd = findCmd {
                var procSuccess = false
                var receiveData: [ATCmdReceiveDataKey: String] = [:]
                let startIndex = procStr.index(procStr.startIndex, offsetBy:ATCmdHelper.CMDCodeStrLength)
                let payload: String = String(procStr[startIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
                switch procCmd {
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
                    case .notSet:
                        break
                }
                
                if procSuccess {
                    return ATCmdReceiveData(command: procCmd, dataAry: receiveData)
                } else {
                    print("Process Payload Not success")
                }
            } else {
                print("No match CMD")
            }
        }
        
        return nil
    }
    
    //讓輸入指令都正規化成 AT+XX
    public static func normalizeStrATCmdAndParam(_ atCmdStr: String?, cutParam: Bool=false) -> String {
        var result: String = "No Set"
        if let procStr = atCmdStr {
            let cmdStr = procStr.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\t", with: "")
            if cmdStr.uppercased().hasPrefix("AT+") {
                if let index = cmdStr.firstIndex(of: " ") {
                    let cmd = cmdStr[..<index]
                    let cmdUP = String(cmd).uppercased()
                    if cutParam {
                        result = cmdUP
                    } else {
                        result = cmdStr.replacingOccurrences(of: cmd, with: cmdUP)
                    }
                    print("normalize CMD uppercased:" + result)
                } else {
                    //Only Cmd
                    result = cmdStr.uppercased()
                    print("normalize All uppercased:" + result)
                }
            }
        }
        return result
    }
    
    public static func convIntToBatteryVoltage(_ value: Int) -> Float {
        return Float(value) * 7.2 / 1023.0
    }
    
    public static func receiveHeaderToHexString(_ recvHeader: UInt16) -> String{
        let str = String(format:"%04X", recvHeader)
        return str
    }
    
    public static func hexStringToFloat(_ hexString: String?) -> Float? {
        if let hexStr = hexString {
            //Str先轉成I32
            if let toInt = self.hexStringToInt(hexStr) {
                //把Int32位元資料當成Float來轉換<注意這邊要用UInt32，位元直接轉換沒影響正負>
                let toFloat = Float(bitPattern: UInt32(toInt))
                return toFloat
            }
        }
        return nil
    }
    
    public static func hexStringToLocationDegrees(_ hexString: String?) -> Double? {
        if let hexStr = hexString {
            //Str先轉成I32
            if let toInt = self.hexStringToInt(hexStr) {
                //把Int32位元資料當成Float來轉換
                let toDouble: Double = Double(toInt) / self.LocationDegreesFixedDivisor
                return toDouble
            }
        }
        return nil
    }
    
    public static func hexStringToInt(_ hexString: String?) -> Int? {
        if let hexStr = hexString {
            return strtol(hexStr, nil, 16)
        }
        return nil
    }
}
