//
//  ATCmdHelper.swift
//  Basic Chat MVC
//
//  Created by wu hsin-hsien on 2023/4/14.
//

import UIKit
import DequeModule

//ATCmd處理 主要用Delegate，特殊情況才考慮用Notifaction

struct ATCmdReceiveData {
    var command: ATCommand
    var dataAry: [ATCmdReceiveDataKey: String]
}

//TODO: 建立AT指令 與 處理回傳資料 與 Queue，指令送出由DeviceMagHelper處理
protocol ATCmdHelperSendDelegate {
    func sendCMDAndParam(cmdStr: String)
}

protocol ATCmdHelperRecvDelegate {
    func recvCMDAndPaylod(cmdData: ATCmdData?)
}

class ATCmdHelper: NSObject {
    static let shared = ATCmdHelper()
    
    public static let CMDCodeStrLength: Int = 4
    public static let CMDReceiveOneTimeEndStr: String = "\nOK\n".lowercased()
    public static let CMDReceiveBatchFinishStr: String = "\nEOF\n".lowercased() //批次傳輸後面無資料
    public static let CMDReceiveBatchContinueStr: String = "\nTBC\n".lowercased() //批次傳輸後面還有資料，要再呼叫CMD抓
    public static let LocationDegreesFixedDivisor: Double = 10000000.0 //座標固定格式 用INT代表 正負1~3位整數部分 + 小數點固定後七位
    public static let LocationDegreesFixedHexLength: Int = 8 //經緯度固定資料長度
    
    public static let CMDSendRetryTimes: Int = 3 //送出出錯時 重試幾次
    public static let CMDSendRetryDelay: TimeInterval = 0.1 //送出出錯時 延遲多少秒重試
    
    public var sendDelegate: ATCmdHelperSendDelegate? = nil
    public var recvDelegate: ATCmdHelperRecvDelegate? = nil
    
    private var ATCmdDeque: Deque<ATCmdData> = []
    
    public func appendATCmdInDeque(cmdData: ATCmdData?) {
        if var data = cmdData {
            data.status = .waitingSend
            ATCmdDeque.append(data)
        }
    }
    
    public func sendFirstATCmdInDeque() -> Bool {
        if let delegate = self.sendDelegate {
            if ATCmdDeque.count > 0 {
                if var cmdData = ATCmdDeque.popFirst() {
                    if let cmdStr = ATCmdHelper.generateToDeviceCmd(cmdData: cmdData) {
                        cmdData.status = .waitingRecv
                        ATCmdDeque.prepend(cmdData)
                        delegate.sendCMDAndParam(cmdStr: cmdStr)
                        
                    } else {
                        print("sendFirstATCmdInDeque Failed Cmd:", cmdData)
                    }
                }
            }
        }
        return false
    }
    
    public func popFirstATCmdInDeque() -> ATCmdData? {
        if ATCmdDeque.count > 0 {
            return ATCmdDeque.popFirst()
        }
        return nil
    }
    
    public func removeAllATCmdInDeque() {
        if ATCmdDeque.count > 0 {
            ATCmdDeque.removeAll()
        }
    }
    
    public static func generateToDeviceCmd(cmdData: ATCmdData?) -> String? {
        if let procData = cmdData {
            if procData.command != .notSet {
                var cmdStr: String
                if procData.send.param.isEmpty {
                    cmdStr = String(format: "%@", procData.command!.rawValue.sendCMD)
                } else {
                    cmdStr = String(format: "%@ %@", procData.command!.rawValue.sendCMD, procData.send.param)
                }
                return cmdStr
            }
        }
        return nil
    }
    
    public static func receiveToData(_ receive: String?) -> ATCmdData? {
        print("receiveToData:", receive ?? "nil")
        if ATCmdHelper.shared.ATCmdDeque.count > 0 {
            if var cmdData = ATCmdHelper.shared.ATCmdDeque.popFirst() {
                if var procStr = receive {
                    if !procStr.lowercased().trimmingCharacters(in: .whitespaces).hasSuffix(CMDReceiveOneTimeEndStr) {
                        if cmdData.status == .waitingRecv {
                            cmdData.recv.rawPayload.append(procStr)
                            ATCmdHelper.shared.ATCmdDeque.prepend(cmdData)
                            print("Data Append:", procStr)
                        }
                        return nil
                    } else {
                        if cmdData.status == .waitingRecv {
                            cmdData.recv.rawPayload.append(procStr)
                            print("CMD End Data Append:", procStr)
                            //清除不要的指令結尾
                            procStr = cmdData.recv.rawPayload.trimmingCharacters(in: .whitespaces)
                            let endIndex = procStr.index(procStr.endIndex, offsetBy:-CMDReceiveOneTimeEndStr.count)
                            procStr = String(procStr[...endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                            cmdData.status = .processingPayload
                            //下面會處理先不用放回Deque
                        } else {
                            //最後要恢復，給調用的地方清除
                            ATCmdHelper.shared.ATCmdDeque.prepend(cmdData)
                            return nil
                        }
                    }
                    
                    var findCmd: ATCommand?
                    
                    for cmd in ATCommand.allCases {
                        if procStr.hasPrefix(cmd.rawValue.recvHeaderStr) {
                            findCmd = cmd
                            print("Find CMD:", cmd)
                            break
                        }
                    }
                    
                    if let procCmd = findCmd {
                        var procSuccess = false
                        if cmdData.status == .processingPayload {
                            var payloadAry: [ATCmdReceiveDataKey: String] = [:]
                            let startIndex = procStr.index(procStr.startIndex, offsetBy:ATCmdHelper.CMDCodeStrLength)
                            let payload: String = String(procStr[startIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
                            switch procCmd {
                                case .GBAT:
                                    if !payload.isEmpty {
                                        payloadAry[ATCmdReceiveDataKey.BatteryLV] = payload
                                        cmdData.recv.payloadAry = payloadAry
                                        procSuccess = true
                                    }
                                    break
                                case .GGPS:
                                    if !payload.isEmpty && payload.count > 16 {
                                        let latEndIndex = payload.index(payload.startIndex, offsetBy:ATCmdHelper.LocationDegreesFixedHexLength)
                                        let latHexStr = String(payload[..<latEndIndex])
                                        let longEndIndex = payload.index(payload.startIndex, offsetBy:ATCmdHelper.LocationDegreesFixedHexLength*2)
                                        let longHexStr = String(payload[latEndIndex..<longEndIndex])
                                        let utcStr = payload[longEndIndex...]
                                        
                                        payloadAry[ATCmdReceiveDataKey.Latitude] = String(ATCmdHelper.hexStringToLocationDegrees(latHexStr) ?? 0.0)
                                        payloadAry[ATCmdReceiveDataKey.Longitude] = String(ATCmdHelper.hexStringToLocationDegrees(longHexStr) ?? 0.0)
                                        payloadAry[ATCmdReceiveDataKey.UTCDate] = String(utcStr)
                                        cmdData.recv.payloadAry = payloadAry
                                        procSuccess = true
                                    }
                                    break
                                case .GTIME:
                                    break
                                case.GVER:
                                    break
                                case .notSet:
                                    break
                            }
                            
                            if procSuccess {
                                cmdData.status = .payloadReady
                                ATCmdHelper.shared.ATCmdDeque.prepend(cmdData)
                                return cmdData
                            } else {
                                print("Process Payload Not success")
                            }
                        } else {
                            print("No match cmd")
                        }
                    }
                }
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
    
    //只取得Param部分
    public static func getOnlyParamStr(atCmdStr: String?) -> String {
        var result: String = ""
        if let procStr = atCmdStr {
            let cmdStr = procStr.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\t", with: "")
            if cmdStr.uppercased().hasPrefix("AT+") {
                if let index = cmdStr.firstIndex(of: " ") {
                    let cmd = cmdStr[..<index]
                    //移除CMD 並把多餘空白消掉
                    result = cmdStr.replacingOccurrences(of: cmd, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
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
