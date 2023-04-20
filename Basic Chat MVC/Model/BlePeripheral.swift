//
//  BlePeripheral.swift
//  Basic Chat MVC
//
//  Created by Trevor Beaton on 2/14/21.
//
//  Updated by Hsinken on 2023/4/20.

import Foundation
import CoreBluetooth


class BlePeripheral {
    static var connectedPeripheral: CBPeripheral?
    static var connectedService: CBService?
    static var connectedTXChar: CBCharacteristic?
    static var connectedRXChar: CBCharacteristic?
    static var connectedAdvertisementData: [String : Any]?
}
