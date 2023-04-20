//
//  ATCmdData.swift
//  Basic Chat MVC
//
//  Created by wu hsin-hsien on 2023/4/20.
//

import Foundation

//Send 的資料叫 param
//Receive 的資料叫 payload

enum ATCmdDataStatus {
    case notSet //資料尚未設定
    case settingCMD //設定要送出指令與資料
    case waitingSend //進入指令隊列
    case retryingSend //送出重試中
    case sendFailed //重試完確定發送失敗
    case sendTimeout //重試完確定發送超時
    case waitingRecv //指令發送完成 等待接收資料
    case receiveFailed //接收失敗
    case receiveTimeout //接收超時
    case receivingPayload //資料傳輸中(因過長資料會分次傳)
    case receiveFinish //資料接收完成
    case processingPayload //處理資料中
    case payloadReady //資料處理完畢可利用
    case canDelete //已利用完畢可刪除
}

enum ATCmdRecvMode {
    case oneTime
    case batch
}

struct ATCmdData {
    var status: ATCmdDataStatus = .notSet
    var send: ATCmdDataSend
    var recv: ATCmdDataRecv
    var updateTime: Date = Date()
}

struct ATCmdDataSend {
    var cmd: ATCmdSendCommand = .NotSet
    var param: String?
    var startTiem: Date?
    var endTiem: Date?
    var retryCount: Int = 0
}

struct ATCmdDataRecv {
    var header: ATCmdReceiveHeader = .NotSet
    var mode: ATCmdRecvMode = .oneTime
    var payload: String?
    var startTiem: Date?
    var endTiem: Date?
}
