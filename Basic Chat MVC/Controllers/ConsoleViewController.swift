//
//  ConsoleViewController.swift
//  Basic Chat
//
//  Created by Trevor Beaton on 2/6/21.
//
//  Updated by Hsinken on 2023/4/20.

import UIKit
import CoreBluetooth

class ConsoleViewController: UIViewController {
    
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
            serviceLabel.text = "Unknown Device Services Count: \(String((BlePeripheral.connectedPeripheral?.services!.count)!))"
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

extension ConsoleViewController: CBPeripheralManagerDelegate {
    
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

extension ConsoleViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let input = textField.text ?? ""
        var at = input
        //Force AT+CMD to uppercased, argvs doesn't uppercase
        if input.uppercased().hasPrefix("AT+") {
            if let index = input.firstIndex(of: " ") {
                let cmd = input[..<index]
                let cmdS = String(cmd).uppercased()
                at = input.replacingOccurrences(of: cmd, with: cmdS)
                //print(cmdS)
                print("CMD uppercased:" + at)
            } else {
                at = input.uppercased()
                print("All uppercased:" + at)
            }
        }
        print("Value Sent: \(at)")
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
