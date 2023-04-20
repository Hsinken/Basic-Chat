//
//  StackingStoneViewController.swift
//  Basic Chat
//
//  Created by Hsinken on 2023/4/20.
//
//  Special for Stacking Stone

import UIKit
import CoreBluetooth

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
        
        keyboardNotifications()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.appendRxDataToTextView(notification:)), name: NSNotification.Name(rawValue: "Notify"), object: nil)
        
        consoleTextField.delegate = self
        
        let connectedPeripheral = BlePeripheral.connectedPeripheral
        peripheralLabel.text = (connectedPeripheral!.name ?? "No Name") + "(" + connectedPeripheral!.identifier.uuidString + ")"
        
        txLabel.text = "TX:\(String(BlePeripheral.connectedTXChar!.uuid.uuidString))"
        rxLabel.text = "RX:\(String(BlePeripheral.connectedRXChar!.uuid.uuidString))"
        
        if let _ = BlePeripheral.connectedService {
            serviceLabel.text = "Stacking Stone Services Count: \(String((BlePeripheral.connectedPeripheral?.services!.count)!))"
        } else{
            print("Service was not found")
        }
        
        consoleTextField.text = "AT+GBAT"
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
                if let rData = ATCmdHelper.receiveToData(recvStr) {
                    print(rData)
                    self.consoleTextView.text.append("\nCMD:" + rData.command.rawValue.recvHeaderStr)
                    self.consoleTextView.text.append("\nPayload:")
                    for item in rData.dataAry {
                        var str: String
                        switch rData.command {
                            case .GBAT:
                                if let conv = ATCmdHelper.hexStringToInt(item.value) {
                                    let batVoltage: Float = ATCmdHelper.convIntToBatteryVoltage(conv)
                                    let convStr = String(conv)
                                    let strS = "\nK:"+item.key.rawValue+"  V(I32 Hex):"
                                    let strM = item.value+"  V(I32 10B):"+convStr+"\n"
                                    let strE = "V(電壓):"+String(batVoltage)+"\n"
                                    str = strS + strM + strE
                                } else {
                                    let strS = "\nK:"+item.key.rawValue+"  V:"
                                    let strE = item.value+"\nV(Int32 10B): Can't Conv.\n"
                                    str = strS + strE
                                }
                                break
                            default:
                                str = "\nK:" + item.key.rawValue + "  V:" + item.value + "\n"
                                break
                        }
                        
                        
                        self.consoleTextView.text.append(str)
                    }
                }
                self.consoleTextView.ScrollToBottom()
            }
        }
    }
    
    func appendTxDataToTextView(CMD: String = ""){
        let currntTime = self.getCurrentLocalTimeString()
        DispatchQueue.main.asyncAfter(deadline:.now() + 0.3) {
            self.consoleTextView.text.append("\n=======\n[Sent] "+currntTime+"\n \(CMD) \n")
            self.consoleTextView.ScrollToBottom()
        }
    }
    
    func keyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
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
    }
    
    // Write functions
    func writeOutgoingValue(data: String){
        let valueString = (data as NSString).data(using: String.Encoding.utf8.rawValue)
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
        //TODO: 改使用ATCmdData來送
        
        
        writeOutgoingValue(data: at)
        appendTxDataToTextView(CMD: at)
        textField.resignFirstResponder()
        //textField.text = ""
        return true
        
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.clearsOnBeginEditing = true
        return true
    }
    
}
