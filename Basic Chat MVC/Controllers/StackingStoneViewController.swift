//
//  StackingStoneViewController.swift
//  Basic Chat
//
//  Created by Hsinken on 2023/4/20.
//
//  Special for Stacking Stone

import UIKit
import CoreBluetooth
import MessageUI

class StackingStoneViewController: UIViewController {
    
    //Data
    var peripheralManager: CBPeripheralManager?
    var peripheral: CBPeripheral?
    var periperalTXCharacteristic: CBCharacteristic?
    
    @IBOutlet weak var peripheralLabel: UILabel!
    @IBOutlet weak var serviceLabel: UILabel!
    @IBOutlet weak var consoleTextView: UITextView!
    @IBOutlet weak var consoleTextField: UITextField!
    @IBOutlet weak var txLabel: UILabel!
    @IBOutlet weak var rxLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        consoleTextField.delegate = self
        self.title = "Stacking Stone"
        self.consoleTextView.delegate = self
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Export",
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(actExport))
        
        let connectedPeripheral = BlePeripheral.connectedPeripheral
        peripheralLabel.text = (connectedPeripheral!.name ?? "No Name")
        
        txLabel.text = "TX:\(String(BlePeripheral.connectedTXChar!.uuid.uuidString))"
        rxLabel.text = "RX:\(String(BlePeripheral.connectedRXChar!.uuid.uuidString))"
        
        if let _ = BlePeripheral.connectedService {
            serviceLabel.text = "Services Count: \(String((BlePeripheral.connectedPeripheral?.services!.count)!))"
        } else{
            print("Service was not found")
        }
        
        consoleTextField.text = "AT+GBAT"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardNotifications()
        ATCmdHelper.shared.sendDelegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(self.appendRxDataToTextView(notification:)), name: NSNotification.Name(rawValue: "Notify"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        ATCmdHelper.shared.removeAllATCmdInDeque()
        ATCmdHelper.shared.sendDelegate = nil
    }
    
    @IBAction func actExport(_ sender: UIBarButtonItem) {
        print("click Export")
        
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        let timestamp = dateFormatter.string(from: now)
        
        let email = "eaterest@gmail.com"
        
        let subject = "Hsinken ITRI BLE Tool Report-"+timestamp
        let deviceName = self.peripheralLabel.text ?? "No name device"
        let console = self.consoleTextView.text ?? "No Data"
        let body =  deviceName + "\n▽▽▼▽▽ Console Start ▽▽▼▽▽" + console + "\n△△▲△△ Console End △△▲△△"
                    
        let coded = "mailto:\(email)?subject=\(subject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            
        if let emailURL:NSURL = NSURL(string: coded!)
        {
            if UIApplication.shared.canOpenURL(emailURL as URL){
                UIApplication.shared.open(emailURL as URL)
            }
        }
    }
    
    func getCurrentLocalTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.'MICROS'"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        
        // Get the number of microseconds with a precision of 6 digits
        let now = Date()
        let dateParts = Calendar.current.dateComponents([.nanosecond], from: now)
        let microSeconds = Int((Double(dateParts.nanosecond!) / 1000).rounded(.toNearestOrEven))
        let microSecPart = String(microSeconds).padding(toLength: 6, withPad: "0", startingAt: 0)
        
        // Format the date and add in the microseconds
        var timestamp = dateFormatter.string(from: now)
        timestamp = timestamp.replacingOccurrences(of: "MICROS", with: microSecPart)
        return timestamp
    }
    
    @objc func appendRxDataToTextView(notification: Notification) -> Void{
        let currntTime = self.getCurrentLocalTimeString()
        DispatchQueue.main.asyncAfter(deadline:.now() + 0.3) {
            if let data = notification.object {
                let recvStr: String = data as! String
                let displayStr: String = recvStr.replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\r", with: "\\r").replacingOccurrences(of: "\t", with: "\\t").replacingOccurrences(of: " ", with: "◇")
                self.consoleTextView.text.append("\n[Recv] "+currntTime+"\n"+displayStr+"\n")
                if let cmdData = ATCmdHelper.receiveToData(recvStr) {
                    print(cmdData)
                    self.consoleTextView.text.append("\nCMD:" + cmdData.command!.rawValue.recvHeaderStr)
                    self.consoleTextView.text.append("\nPayload:")
                    if cmdData.status == .payloadReady {
                        var str: String
                        switch cmdData.command {
                            case .GBAT:
                                let payloadKey = ATCmdReceiveDataKey.BatteryLV
                                if let batLv = cmdData.recv.payloadAry[payloadKey] {
                                    if let conv = ATCmdHelper.hexStringToInt(batLv) {
                                        let batVoltage: Float = ATCmdHelper.convIntToBatteryVoltage(conv)
                                        let convStr = String(conv)
                                        let strS = "\nK:"+payloadKey.rawValue+"  V(I32 Hex):"
                                        let strM = batLv+"  V(I32 10B):"+convStr+"\n"
                                        let strE = "V(電壓):"+String(batVoltage)+"\n"
                                        str = strS + strM + strE
                                    } else {
                                        let strS = "\nK:"+payloadKey.rawValue+"  V:"
                                        let strE = batLv+"\nV(Int32 10B): Can't Conv.\n"
                                        str = strS + strE
                                    }
                                    self.consoleTextView.text.append(str)
                                }
                                break
                            case .GGPS:
                                let latKey = ATCmdReceiveDataKey.Latitude
                                let longKey = ATCmdReceiveDataKey.Longitude
                                let utcKey = ATCmdReceiveDataKey.UTCDate
                                if let latStr = cmdData.recv.payloadAry[latKey] {
                                    str = "\nK:"+latKey.rawValue+"  V:" + latStr
                                    self.consoleTextView.text.append(str)
                                }
                                if let longStr = cmdData.recv.payloadAry[longKey] {
                                    str = "\nK:"+longKey.rawValue+"  V:" + longStr
                                    self.consoleTextView.text.append(str)
                                }
                                if let utcStr = cmdData.recv.payloadAry[utcKey] {
                                    str = "\nK:"+utcKey.rawValue+"  V:" + utcStr
                                    self.consoleTextView.text.append(str)
                                }
                                //let gpsUrlBase = "https://maps.google.com/?q=25.1353333,121.4629466"
                                let gpsUrlBase = "https://maps.google.com/?q="
                                let gpsUrl = String(format: "%@%@,%@", gpsUrlBase, cmdData.recv.payloadAry[latKey]!, cmdData.recv.payloadAry[longKey]!)
                                //最後樣式不能是Link會往後覆蓋
                                self.consoleTextView.addHyperLinksToText(originalText: "\n開啟 GPS位置 地圖\n", hyperLinks: ["GPS位置": gpsUrl])
                                break
                            default:
                                for item in cmdData.recv.payloadAry {
                                    str = "\nK:" + item.key.rawValue + "  V:" + item.value
                                }
                                break
                        }
                        let _ = ATCmdHelper.shared.popFirstATCmdInDeque()
                    }
                }
                self.consoleTextView.ScrollToBottom()
            }
        }
    }
    
    func appendTxDataToTextView(cmdStr: String = ""){
        let currntTime = self.getCurrentLocalTimeString()
        DispatchQueue.main.asyncAfter(deadline:.now() + 0.3) {
            self.consoleTextView.text.append("\n=======\n[Sent] "+currntTime+"\n \(cmdStr) \n")
            self.consoleTextView.ScrollToBottom()
        }
    }
    
    func keyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    // MARK:- Keyboard
    @objc func keyboardWillChange(notification: Notification) {
        
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            let keyboardHeight = keyboardSize.height
            //print(keyboardHeight)
            view.frame.origin.y = (-keyboardHeight + 34*0.5)
        }
    }
    
    @objc func keyboardDidHide(notification: Notification) {
        view.frame.origin.y = 0
    }
    
    @objc func disconnectPeripheral() {
        print("Disconnect for peripheral.")
        let alertVC = UIAlertController(title: "Bluetooth Required", message: "Disconnect for peripheral.", preferredStyle: UIAlertController.Style.alert)
        
        let action = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
            self.dismiss(animated: true, completion: nil)
        })
        
        alertVC.addAction(action)
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    // Write functions
    func writeOutgoingValue(cmdStr: String){
        let valueString = (cmdStr as NSString).data(using: String.Encoding.utf8.rawValue)
        //change the "data" to valueString
        if let blePeripheral = BlePeripheral.connectedPeripheral {
            if let txCharacteristic = BlePeripheral.connectedTXChar {
                //blePeripheral.writeValue(valueString!, for: txCharacteristic, type: CBCharacteristicWriteType.withResponse)
                //Hiking用withoutResponse + Notify模式溝通
                blePeripheral.writeValue(valueString!, for: txCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
            }
        }
    }
    
    //目前沒操作到
    func writeCharacteristic(incomingValue: Int8){
        var val = incomingValue
        
        let outgoingData = NSData(bytes: &val, length: MemoryLayout<Int8>.size)
        if let blePeripheral = BlePeripheral.connectedPeripheral {
            blePeripheral.writeValue(outgoingData as Data, for: BlePeripheral.connectedTXChar!, type: CBCharacteristicWriteType.withResponse)
        }
    }
}

extension StackingStoneViewController: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
            case .poweredOn:
                print("Peripheral Is Powered On.")
            case .unsupported:
                print("Peripheral Is Unsupported.")
            case .unauthorized:
                print("Peripheral Is Unauthorized.")
            case .unknown:
                print("Peripheral Unknown")
            case .resetting:
                print("Peripheral Resetting")
            case .poweredOff:
                print("Peripheral Is Powered Off.")
            @unknown default:
                print("Error")
        }
    }
    
    
    //Check when someone subscribe to our characteristic, start sending the data
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Device subscribe to characteristic")
    }
    
}

extension StackingStoneViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let inputText = textField.text ?? ""
        //Force AT+CMD to uppercased, argvs doesn't uppercase
        let at = ATCmdHelper.normalizeStrATCmdAndParam(inputText)
        print("Value Sent: \(at)", "\n")
        
        let onlyCmd: String = ATCmdHelper.normalizeStrATCmdAndParam(inputText, cutParam: true)
        let command = ATCommand(sendCMD: onlyCmd)
        print("inputText Conv Command:", command ?? "Not Found")
        
        let onlyParam: String = ATCmdHelper.getOnlyParamStr(atCmdStr: inputText)
        print("inputText Conv Param:", onlyParam, "\n")
        
        var sendData = ATCmdDataSend()
        sendData.param = onlyParam
        var recvData = ATCmdDataRecv()
        recvData.mode = .oneTime
        
        var cmdData = ATCmdData(send: sendData,
                                recv: recvData)
        cmdData.command = command ?? .notSet
        if cmdData.command != .notSet {
            ATCmdHelper.shared.appendATCmdInDeque(cmdData: cmdData)
            let _ = ATCmdHelper.shared.sendFirstATCmdInDeque()
        } else {
            writeOutgoingValue(cmdStr: at)
            appendTxDataToTextView(cmdStr: at)
        }
        
        textField.resignFirstResponder()
        //textField.text = ""
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.clearsOnBeginEditing = true
        return true
    }
    
}

extension StackingStoneViewController : ATCmdHelperSendDelegate {
    func sendCMDAndParam(cmdStr: String) {
        self.writeOutgoingValue(cmdStr: cmdStr)
        self.appendTxDataToTextView(cmdStr: cmdStr)
    }
}

extension StackingStoneViewController : UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        
        //if (URL.absoluteString == "https://google.com") {
        if (URL.absoluteString.count > 0) {
            UIApplication.shared.open(URL) { (Bool) in
            }
        }
        return false
    }
}
