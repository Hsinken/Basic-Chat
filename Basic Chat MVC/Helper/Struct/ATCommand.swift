//
//  ATCommand.swift
//  Basic Chat MVC
//
//  Created by wu hsin-hsien on 2023/4/20.
//

import Foundation

struct ConstATCmd {
    static let GBAT_SendCMD: String = "AT+GBAT"
    static let GBAT_RecvHeader: UInt16 = 0x0274
    static let GBAT_RecvHeaderStr: String = ATCmdHelper.receiveHeaderToHexString(0x0274)
    
    static let GGPS_SendCMD: String = "AT+GGPS"
    static let GGPS_RecvHeader: UInt16 = 0x0288
    static let GGPS_RecvHeaderStr: String = ATCmdHelper.receiveHeaderToHexString(0x0288)
    
    static let GTIME_SendCMD: String = "AT+GTIME"
    static let GTIME_RecvHeader: UInt16 = 0x0501
    static let GTIME_RecvHeaderStr: String = ATCmdHelper.receiveHeaderToHexString(0x0501)
    
    static let GVER_SendCMD: String = "AT+GVER"
    static let GVER_RecvHeader: UInt16 = 0x0502
    static let GVER_RecvHeaderStr: String = ATCmdHelper.receiveHeaderToHexString(0x0502)
    
    static let NotSet_SendCMD: String = "ATCmd NotSet"
    static let NotSet_RecvHeader: UInt16 = 0x0000
    static let NotSet_RecvHeaderStr: String = ATCmdHelper.receiveHeaderToHexString(0x0000)
}

struct ATCmdCode {
    var sendCMD :String = ConstATCmd.NotSet_SendCMD
    var recvHeader :UInt16 = ConstATCmd.NotSet_RecvHeader
    var recvHeaderStr :String = ConstATCmd.NotSet_RecvHeaderStr
}

enum ATCommand : CaseIterable {
    case GBAT
    case GGPS
    case GTIME
    case GVER
    case notSet
}

extension ATCommand : RawRepresentable {
    typealias RawValue = ATCmdCode
    
    init?(rawValue: Self.RawValue){
        switch rawValue {
            default: return nil
        }
    }
    
    init?(recvHeader: UInt16) {
        switch recvHeader {
            case ConstATCmd.GBAT_RecvHeader : self = .GBAT
            case ConstATCmd.GGPS_RecvHeader : self = .GGPS
            case ConstATCmd.GTIME_RecvHeader : self = .GTIME
            case ConstATCmd.GVER_RecvHeader : self = .GVER
            default: return nil
        }
    }
    
    init?(recvHeaderStr: String) {
        switch recvHeaderStr {
            case ConstATCmd.GBAT_RecvHeaderStr : self = .GBAT
            case ConstATCmd.GGPS_RecvHeaderStr : self = .GGPS
            case ConstATCmd.GTIME_RecvHeaderStr : self = .GTIME
            case ConstATCmd.GVER_RecvHeaderStr : self = .GVER
            default: return nil
        }
    }
    
    init?(sendCMD: String) {
        switch sendCMD {
            case ConstATCmd.GBAT_SendCMD : self = .GBAT
            case ConstATCmd.GGPS_SendCMD : self = .GGPS
            case ConstATCmd.GTIME_SendCMD : self = .GTIME
            case ConstATCmd.GVER_SendCMD : self = .GVER
            default: return nil
        }
    }

    var rawValue: RawValue {
        switch self {
            case .GBAT: return ATCmdCode(sendCMD:ConstATCmd.GBAT_SendCMD,
                                         recvHeader: ConstATCmd.GBAT_RecvHeader,
                                         recvHeaderStr: ConstATCmd.GBAT_RecvHeaderStr)
            case .GGPS: return ATCmdCode(sendCMD:ConstATCmd.GGPS_SendCMD,
                                         recvHeader: ConstATCmd.GGPS_RecvHeader,
                                         recvHeaderStr: ConstATCmd.GGPS_RecvHeaderStr)
            case .GTIME: return ATCmdCode(sendCMD:ConstATCmd.GTIME_SendCMD,
                                         recvHeader: ConstATCmd.GTIME_RecvHeader,
                                          recvHeaderStr: ConstATCmd.GTIME_RecvHeaderStr)
            case .GVER: return ATCmdCode(sendCMD:ConstATCmd.GVER_SendCMD,
                                         recvHeader: ConstATCmd.GVER_RecvHeader,
                                         recvHeaderStr: ConstATCmd.GVER_RecvHeaderStr)
            default: return ATCmdCode(sendCMD:ConstATCmd.NotSet_SendCMD,
                                      recvHeader: ConstATCmd.NotSet_RecvHeader,
                                      recvHeaderStr: ConstATCmd.NotSet_RecvHeaderStr)
        }
    }
}
