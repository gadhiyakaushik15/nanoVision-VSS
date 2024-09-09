//
//  UserDefaults.swift
//  Paravision
//
//  Created by Kaushik Gadhiya on 10/01/24.
//

import Foundation
import KeychainSwift

class UserDefaultsServices {
    
    //MARK: enum for all user default keys
    enum UserDefaultsKeys: String {
        case accessToken
        case refreshToken
        case devicesDetails
        case isManualScanMode
        case isLiveness
        case isValidness
        case peoplesLastSyncDate
        case logsLastSyncDate
        case isScanSound
        case nextScanDelay
        case isTapScanSuccess
        case isTapScanFailure
        case selectedDay
        case selectedLocation
    }
    
    //MARK: shared instance
    static let shared = UserDefaultsServices()
    
    //MARK: variable for userdefault
    let userDefaults: UserDefaults = UserDefaults.standard
    
    func isLogin() -> Bool {
        if  let data = self.userDefaults.value(forKey: UserDefaultsKeys.accessToken.rawValue),  let _ = data as? String {
            return true
        } else {
            return false
        }
    }
    
    //MARK: Set And Get Access Token
    func saveAccessToken(token: String) {
        self.userDefaults.setValue(token, forKey: UserDefaultsKeys.accessToken.rawValue)
    }
    func getAccessToken() -> String {
        if  let data = self.userDefaults.value(forKey: UserDefaultsKeys.accessToken.rawValue), let token = data as? String {
            return token
        } else {
            return ""
        }
    }
    
    //MARK: Set And Get Refresh Token
    func saveRefreshToken(token: String) {
        self.userDefaults.setValue(token, forKey: UserDefaultsKeys.refreshToken.rawValue)
    }
    func getRefreshToken() -> String {
        if  let data = self.userDefaults.value(forKey: UserDefaultsKeys.refreshToken.rawValue), let token = data as? String {
            return token
        } else {
            return ""
        }
    }
    
    //MARK: Set And Get Devices Details
    func saveDevicesDetails(devicesDetails: DevicesDetail) {
        guard let data = try? JSONEncoder().encode(devicesDetails) else {
           return
         }
        self.userDefaults.setValue(data, forKey: UserDefaultsKeys.devicesDetails.rawValue)
    }
    func getDevicesDetails() -> DevicesDetail? {
        if  let data = self.userDefaults.value(forKey: UserDefaultsKeys.devicesDetails.rawValue), let devicesDetailsData = data as? Data, let devicesDetails = try? JSONDecoder().decode(DevicesDetail.self, from: devicesDetailsData) {
            return devicesDetails
        } else {
            return nil
        }
    }
    
    //MARK: Set And Get Is Manual Scan Mode
    func saveManualScanMode(value: Bool) {
        self.userDefaults.setValue(value, forKey: UserDefaultsKeys.isManualScanMode.rawValue)
    }
    func isManualScanMode() -> Bool {
        if  let data = self.userDefaults.value(forKey: UserDefaultsKeys.isManualScanMode.rawValue), let isManualScanMode = data as? Bool {
            return isManualScanMode
        } else {
            return false
        }
    }
    
    //MARK: Set And Get Is Liveness
    func saveLiveness(value: Bool) {
        self.userDefaults.setValue(value, forKey: UserDefaultsKeys.isLiveness.rawValue)
    }
    func isLiveness() -> Bool {
        if  let data = self.userDefaults.value(forKey: UserDefaultsKeys.isLiveness.rawValue), let isLiveness = data as? Bool {
            return isLiveness
        } else {
            return false
        }
    }
    
    //MARK: Set And Get Is Validness
    func saveValidness(value: Bool) {
        self.userDefaults.setValue(value, forKey: UserDefaultsKeys.isValidness.rawValue)
    }
    func isValidness() -> Bool {
        if  let data = self.userDefaults.value(forKey: UserDefaultsKeys.isValidness.rawValue), let isValidness = data as? Bool {
            return isValidness
        } else {
            return false
        }
    }
    
    //MARK: Set And Get Peoples Last Sync Date
    func savePeoplesLastSyncDate(date: String) {
        self.userDefaults.setValue(date, forKey: UserDefaultsKeys.peoplesLastSyncDate.rawValue)
    }
    func getPeoplesLastSyncDate() -> String? {
        if  let data = self.userDefaults.value(forKey: UserDefaultsKeys.peoplesLastSyncDate.rawValue), let token = data as? String {
            return token
        } else {
            return nil
        }
    }
    
    //MARK: Set And Get Logs Last Sync Date
    func saveLogsLastSyncDate(date: String) {
        self.userDefaults.setValue(date, forKey: UserDefaultsKeys.logsLastSyncDate.rawValue)
    }
    func getLogsLastSyncDate() -> String? {
        if  let data = self.userDefaults.value(forKey: UserDefaultsKeys.logsLastSyncDate.rawValue), let token = data as? String {
            return token
        } else {
            return nil
        }
    }
    
    //MARK: Set And Get Is Scan Sound
    func saveScanSound(value: Bool) {
        self.userDefaults.setValue(value, forKey: UserDefaultsKeys.isScanSound.rawValue)
    }
    func isScanSound() -> Bool {
        if  let data = self.userDefaults.value(forKey: UserDefaultsKeys.isScanSound.rawValue), let isScanSound = data as? Bool {
            return isScanSound
        } else {
            return false
        }
    }
    
    //MARK: Set And Get Next Scan Delay
    func saveNextScanDelay(value: Float) {
        self.userDefaults.setValue(value, forKey: UserDefaultsKeys.nextScanDelay.rawValue)
    }
    func getNextScanDelay() -> Float {
        if  let data = self.userDefaults.value(forKey: UserDefaultsKeys.nextScanDelay.rawValue), let token = data as? Float {
            return token
        } else {
            return Constants.NextScanDelayDefault
        }
    }
    
    //MARK: Set And Get Is Tap to Scan on Success
    func saveTapScanSuccess(value: Bool) {
        self.userDefaults.setValue(value, forKey: UserDefaultsKeys.isTapScanSuccess.rawValue)
    }
    func isTapScanSuccess() -> Bool {
        if  let data = self.userDefaults.value(forKey: UserDefaultsKeys.isTapScanSuccess.rawValue), let isTapScanSuccess = data as? Bool {
            return isTapScanSuccess
        } else {
            return false
        }
    }
    
    //MARK: Set And Get Is Tap to Scan on Failure
    func saveTapScanFailure(value: Bool) {
        self.userDefaults.setValue(value, forKey: UserDefaultsKeys.isTapScanFailure.rawValue)
    }
    func isTapScanFailure() -> Bool {
        if  let data = self.userDefaults.value(forKey: UserDefaultsKeys.isTapScanFailure.rawValue), let isTapScanFailure = data as? Bool {
            return isTapScanFailure
        } else {
            return false
        }
    }
    
    //MARK: Set And Get Selected Day
    func saveSelectedDay(day: String) {
        self.userDefaults.setValue(day, forKey: UserDefaultsKeys.selectedDay.rawValue)
    }
    func getSelectedDay() -> String {
        if  let data = self.userDefaults.value(forKey: UserDefaultsKeys.selectedDay.rawValue), let day = data as? String {
            return day
        } else {
            return ""
        }
    }
    
    //MARK: Set And Get Selected Location
    func saveSelectedLocation(location: String) {
        self.userDefaults.setValue(location, forKey: UserDefaultsKeys.selectedLocation.rawValue)
    }
    func getSelectedLocation() -> String {
        if  let data = self.userDefaults.value(forKey: UserDefaultsKeys.selectedLocation.rawValue), let location = data as? String {
            return location
        } else {
            return ""
        }
    }
}
