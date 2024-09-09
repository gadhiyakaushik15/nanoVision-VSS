//
//  Keychain.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 05/04/24.
//

import Foundation
import KeychainSwift

class KeychainServices {
    
    //MARK: enum for all keychain keys
    enum UserDefaultsKeys: String {
        case deviceMac
        case appLogId
    }
    
    //MARK: shared instance
    static let shared = KeychainServices()
    
    //MARK: variable for keychain
    let Keychain = KeychainSwift()
    
    //MARK: Set And Get Device Mac
    func saveDeviceMac(deviceMac: String) {
        self.Keychain.set(deviceMac, forKey: UserDefaultsKeys.deviceMac.rawValue)
    }
    func getDeviceMac() -> String {
        if  let deviceMac = self.Keychain.get(UserDefaultsKeys.deviceMac.rawValue) {
            return deviceMac
        } else {
            return ""
        }
    }
    
    //MARK: Set And Get App Log Id
    func saveAppLogId(appLogId: String) {
        self.Keychain.set(appLogId, forKey: UserDefaultsKeys.appLogId.rawValue)
    }
    func getAppLogId() -> String {
        if  let appLogId = self.Keychain.get(UserDefaultsKeys.appLogId.rawValue) {
            return appLogId
        } else {
            return ""
        }
    }
}
