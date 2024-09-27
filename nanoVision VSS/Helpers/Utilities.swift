//
//  Utilities.swift
//  Paravision
//
//  Created by Kaushik Gadhiya on 09/01/24.
//

import Foundation
import UIKit
import SVProgressHUD
import SideMenu

class Utilities {
    static let shared = Utilities()
    
    func showSVProgressHUD(){
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setBackgroundColor(UIColor(named: "blueBackgroundColor") ?? .lightGray)
        SVProgressHUD.setForegroundColor(UIColor(named: "whiteLabelColor") ?? .white)
    }
    
    func showSVProgressHUD(message: String){
        SVProgressHUD.show(withStatus: message)
        SVProgressHUD.setBackgroundColor(UIColor(named: "blueBackgroundColor") ?? .lightGray)
        SVProgressHUD.setForegroundColor(UIColor(named: "whiteLabelColor") ?? .white)
    }
    
    func showSuccessSVProgressHUD(message: String){
        SVProgressHUD.showSuccess(withStatus: message)
        SVProgressHUD.setBackgroundColor(UIColor(named: "blueBackgroundColor") ?? .lightGray)
        SVProgressHUD.setForegroundColor(UIColor(named: "whiteLabelColor") ?? .white)
    }
    
    func dismissSVProgressHUD(){
        SVProgressHUD.dismiss()
    }
    
    func sideMenuSettings(leftSideMenu: SideMenuNavigationController) {
        let presentationStyle: SideMenuPresentationStyle = .menuSlideIn
        presentationStyle.menuStartAlpha = 1
        presentationStyle.menuScaleFactor = 0.99
        presentationStyle.onTopShadowOpacity = 0.99
        presentationStyle.presentingEndAlpha = 1
        presentationStyle.presentingScaleFactor = 1
        
        var settings = SideMenuSettings()
        settings.presentationStyle = presentationStyle
        if self.isPadDevice() {
            settings.menuWidth = UIScreen.main.bounds.width / 1.35
        } else {
            settings.menuWidth = UIScreen.main.bounds.width - 40
        }
        leftSideMenu.settings = settings
    }
    
    func isPadDevice() -> Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        } else {
            return false
        }
    }
    
    func logout() {
        if self.isMQTTEnabled() {
            if MQTTAppState.shared().appConnectionState.isConnected {
                MQTTManager.shared().disconnect()
            }
        }
        LocalDataService.shared.stopTimer()
        UserDefaultsServices.shared.removeLastSyncTimeStamp()
        LocalDataService().deleteCSV()
        LocalDataService.shared.createLogs(isSync: false)
        UserDefaultsServices.shared.userDefaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
        UserDefaultsServices.shared.userDefaults.synchronize()
        OfflineDevicesDetails.shared.devicesDetails = nil
    }
    
    func addSideRadiusWithOpacity(view: UIView, radius: CGFloat, shadowRadius: CGFloat, opacity: Float,shadowOffset:CGSize, shadowColor:UIColor, corners: UIRectCorner) {
        view.layer.shadowOffset = shadowOffset
        view.layer.shadowOpacity = opacity
        view.layer.cornerRadius = radius
        view.layer.shadowRadius = shadowRadius
        view.layer.shadowColor = shadowColor.cgColor
        view.clipsToBounds = true
        view.layer.masksToBounds = false
        view.layer.maskedCorners = CACornerMask(rawValue: corners.rawValue)
    }
    
    //MARK: - String to NSDate format
    func convertStringToNSDateFormat(date: String, currentFormat: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateStyle  = .full
        dateFormatter.dateFormat = currentFormat
        let nsDate = dateFormatter.date(from: date)
        return nsDate
    }
    
    //MARK: - NSDate to String format
    func convertNSDateToStringFormat(date: Date, requiredFormat: String, isSmallAmPm: Bool = false) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateStyle = .full
        dateFormatter.dateFormat = requiredFormat
        if isSmallAmPm {
            dateFormatter.amSymbol = "am"
            dateFormatter.pmSymbol = "pm"
        }
        let dateToBeSaved = dateFormatter.string(from: date)
        return dateToBeSaved
    }
    
    func convertDateToString(date : Date, requiredFormat: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = requiredFormat
        let dateToBeSaved = dateFormatter.string(from: date)
        return dateToBeSaved
    }
    
    func getTopPresentedController() -> UIViewController? {
        if let keyWindow = UIApplication.shared.currentUIWindow() {
            if var topController = keyWindow.rootViewController {
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }
                if let navigationController = topController as? UINavigationController, let visibleViewController = navigationController.visibleViewController {
                    topController = visibleViewController
                }
                return topController
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func getAppLogo() -> UIImage {
        if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails, let kioskDetails = devicesDetails.kioskDetails, let kioskDetail = kioskDetails.first, let appLogo = kioskDetail.appLogo {
            return appLogo.convertBase64StringToImage()
        } else {
            return UIImage()
        }
    }
    
    func getSelectedEventName() -> String {
        if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails, let eventIdDetails = devicesDetails.eventidDetails,  let eventIdDetail = eventIdDetails.first, let eventName = eventIdDetail.eventname {
            return eventName
        } else {
            return "-"
        }
    }
    
    func getSelectedEventId() -> Int? {
        if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails, let eventIdDetails = devicesDetails.eventidDetails,  let eventIdDetail = eventIdDetails.first, let eventid = eventIdDetail.eventid {
            return eventid
        } else {
            return nil
        }
    }
    
    func getDeviceId() -> Int? {
        if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails, let devices = devicesDetails.device, let device = devices.first, let deviceId = device.deviceid {
            return deviceId
        } else {
            return nil
        }
    }
    
    func getAccessControllerName() -> String? {
        if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails, let devices = devicesDetails.device, let device = devices.first, let accessControlerName = device.accesscontrolername {
            return accessControlerName
        } else {
            return nil
        }
    }
    
    func getAssignedRelay() -> Int? {
        if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails, let devices = devicesDetails.device, let device = devices.first, let assignedRelay = device.assignedrelay, let assignedRelayInt = Int(assignedRelay) {
            return assignedRelayInt
        } else {
            return nil
        }
    }
    
    func isMQTTEnabled() -> Bool {
        if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails, let devices = devicesDetails.device, let device = devices.first, let mqttEnabled = device.mqttenabled {
            return mqttEnabled
        } else {
            return false
        }
    }
    
    //MARK: - Email Validation
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
