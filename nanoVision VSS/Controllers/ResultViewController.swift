//
//  ResultViewController.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 08/04/24.
//

import UIKit
import ParavisionFL
import SideMenu

enum ParavisionType {
    case faceRecognition
    case faceValidness
    case faceLiveness
    case qrCode
}

enum ScanType: Int {
    case success = 1
    case livenessFailed = 2
    case futureEvent = 3
    case expiredEvent = 4
    case unauthorized = 5
}

class ResultViewController: UIViewController {
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    
    var data = [PeoplesModel]()
    var imageBase64: Data?
    var type: ParavisionType = .faceValidness
    var validness: PNLivenessValidness?
    var liveness: PNLiveness?
    var scanType: ScanType?
    var isPresented = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.SetMessageUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setLogo()
        LocalDataService.shared.syncCompleted = {
            self.setLogo()
            if Utilities.shared.isMQTTEnabled() {
                MQTTManager.shared().checkRelayChange()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.isPresented = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.isPresented {
            self.isPresented = false
            self.autoDismiss()
        }
    }
    
    // MARK: Set Logo
    func setLogo() {
        self.logoImageView.image = Utilities.shared.getAppLogo()
    }
    
    func SetMessageUI() {
        var logMatchScore = 0
        var message = ""
        var logPeopleId = 0
        var logPeopleName = ""
        var apiResponse = ""
        var listId = ""
        var logEventId: Int?
        var logEventName = ""
        var logDeviceId: Int?
        var scanType: ScanType = .success
        var logUserType = ""
        var logUniqueId = ""
        
        if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails {
            if let eventIdDetails = devicesDetails.eventidDetails, let eventIdDetail = eventIdDetails.first {
                if let eventId = eventIdDetail.eventid {
                    logEventId = eventId
                }
                if let eventname = eventIdDetail.eventname {
                    logEventName = eventname
                }
            }
            if let devices = devicesDetails.device, let device = devices.first, let deviceId = device.deviceid {
                logDeviceId = deviceId
            }
        }
        
        if let validness = self.validness {
            apiResponse = String(describing: validness)
            if let liveness = self.liveness {
                apiResponse = apiResponse + " " + String(describing: liveness)
            }
        } else {
            if let liveness = self.liveness {
                apiResponse = String(describing: liveness)
            }
        }
        debugPrint("apiResponse = \(apiResponse)")
        
        if self.type == .faceValidness {
            scanType = .livenessFailed
            self.statusView.backgroundColor = .warningScanColor
            message = "Liveness check failed"
            var validnessfeedback = ""
            if let validness = self.validness, let feedbacks = validness.feedbacks.first {
                switch feedbacks {
                case .FACE_ACCEPTABILITY_POOR:
                    validnessfeedback = "Face acceptability poor"
                    break
                case .UNKNOWN:
                    validnessfeedback = "Face acceptability poor"
                    break
                case .FACE_QUALITY_POOR:
                    validnessfeedback = "Face quality poor"
                    break
                case .IMG_LIGHTING_DARK:
                    validnessfeedback = "Image lighting dark"
                    break
                case .IMG_LIGHTING_BRIGHT:
                    validnessfeedback = "Image lighting bright"
                    break
                case .FACE_SIZE_SMALL:
                    validnessfeedback = "Face size small"
                    break
                case .FACE_SIZE_LARGE:
                    validnessfeedback = "Face size large"
                    break
                case .FACE_POS_LEFT:
                    validnessfeedback = "Face position left"
                    break
                case .FACE_POS_RIGHT:
                    validnessfeedback = "Face position right"
                    break
                case .FACE_POS_HIGH:
                    validnessfeedback = "Face position high"
                    break
                case .FACE_POS_LOW:
                    validnessfeedback = "Face position low"
                    break
                case .FACE_MASK_FOUND:
                    validnessfeedback = "Face mask found"
                    break
                case .FACE_FRONTALITY_POOR:
                    validnessfeedback = "Face acceptability poor"
                    break
                case .FACE_SHARPNESS_POOR:
                    validnessfeedback = "Face sharpness poor"
                    break
                @unknown default:
                    validnessfeedback = "Face acceptability poor"
                    break
                }
            }
            self.nameLabel.textAlignment = .center
            self.nameLabel.text = "\(message)\n\n\(validnessfeedback)"
        } else if self.type == .faceLiveness {
            if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails, let eventIdDetails = devicesDetails.eventidDetails, let eventIdDetail = eventIdDetails.first, let eventId = eventIdDetail.eventid, self.data.count > 0 {
                if let matched = self.data.max(by: { first, second in
                    if let peopleEventId = second.eventID, eventId == peopleEventId {
                        return true
                    } else if let peopleEventId = first.eventID, eventId == peopleEventId {
                        return false
                    } else {
                        if (first.matchScore ?? 0) < (second.matchScore ?? 0) {
                            return true
                        } else {
                            return false
                        }
                    }
                }) {
                    if let matchScore = matched.matchScore {
                        logMatchScore = matchScore
                    }
                    if let peopleId = matched.peopleid {
                        logPeopleId = peopleId
                    }
                    if let uniqueId = matched.uniqueId {
                        logUniqueId = uniqueId
                    }
                    logPeopleName = "\(matched.firstname ?? "") \(matched.lastname ?? "")"
                    logUserType = matched.usertype ?? ""
                    if let listIdArray = matched.listid {
                        listId = listIdArray.joined(separator: ",")
                    }
                }
            }
            scanType = .livenessFailed
            self.statusView.backgroundColor = .warningScanColor
            message = "Liveness check failed"
            self.nameLabel.textAlignment = .center
            self.nameLabel.text = "\(message)\n\nReason: Oops! It seems the image is either blurred or not an actual person. Ensure a clear and well-lit view of your face, and try again."
        } else {
            if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails, let eventIdDetails = devicesDetails.eventidDetails, let eventIdDetail = eventIdDetails.first, let kioskDetails = devicesDetails.kioskDetails, let kioskDetail = kioskDetails.first {
                
                var isFutureEvent = false
                var isExpiredEvent = false
                
                if let enableFutureEventScan = kioskDetail.enablefutureeventscan, enableFutureEventScan == false {
                    if let eventStartDateTime = eventIdDetail.eventstartdatetime, let eventStartDate = Utilities.shared.convertStringToNSDateFormat(date: eventStartDateTime, currentFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ"), Date().toLocalTime() < eventStartDate {
                        isFutureEvent = true
                    } else if let enableExpiredEventScan = kioskDetail.enableexpiredeventscan, enableExpiredEventScan == false {
                        if let eventEndDateTime = eventIdDetail.eventenddatetime, let eventEndDate = Utilities.shared.convertStringToNSDateFormat(date: eventEndDateTime, currentFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ"),  Date().toLocalTime() > eventEndDate{
                            isExpiredEvent = true
                        }
                    }
                } else if let enableExpiredEventScan = kioskDetail.enableexpiredeventscan, enableExpiredEventScan == false {
                    if let eventEndDateTime = eventIdDetail.eventenddatetime, let eventEndDate = Utilities.shared.convertStringToNSDateFormat(date: eventEndDateTime, currentFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ"),  Date().toLocalTime() > eventEndDate{
                        isExpiredEvent = true
                    }
                }
                
                if isFutureEvent {
                    scanType = .futureEvent
                    self.statusView.backgroundColor = .warningScanColor
                    if let futureEventScanMsg = kioskDetail.futureeventscanmsg, futureEventScanMsg != "" {
                        message = futureEventScanMsg
                    } else {
                        message = Message.FutureEventMessage
                    }
                    self.nameLabel.textAlignment = .center
                    self.nameLabel.text = message
                    if let eventId = eventIdDetail.eventid, self.data.count > 0 {
                        if let matched = self.data.max(by: { first, second in
                            if let peopleEventId = second.eventID, eventId == peopleEventId {
                                return true
                            } else if let peopleEventId = first.eventID, eventId == peopleEventId {
                                return false
                            } else {
                                if (first.matchScore ?? 0) < (second.matchScore ?? 0) {
                                    return true
                                } else {
                                    return false
                                }
                            }
                        }) {
                            if let matchScore = matched.matchScore {
                                logMatchScore = matchScore
                            }
                            if let peopleId = matched.peopleid {
                                logPeopleId = peopleId
                            }
                            if let uniqueId = matched.uniqueId {
                                logUniqueId = uniqueId
                            }
                            logPeopleName = "\(matched.firstname ?? "") \(matched.lastname ?? "")"
                            logUserType = matched.usertype ?? ""
                            if let listIdArray = matched.listid {
                                listId = listIdArray.joined(separator: ",")
                            }
                        }
                    }
                } else if isExpiredEvent {
                    scanType = .expiredEvent
                    self.statusView.backgroundColor = .warningScanColor
                    if let expiredEventScanMsg = kioskDetail.expiredeventscanmsg, expiredEventScanMsg != "" {
                        message = expiredEventScanMsg
                    } else {
                        message = Message.ExpiredEventMessage
                    }
                    self.nameLabel.textAlignment = .center
                    self.nameLabel.text = message
                    if let eventId = eventIdDetail.eventid, self.data.count > 0 {
                        if let matched = self.data.max(by: { first, second in
                            if let peopleEventId = second.eventID, eventId == peopleEventId {
                                return true
                            } else if let peopleEventId = first.eventID, eventId == peopleEventId {
                                return false
                            } else {
                                if (first.matchScore ?? 0) < (second.matchScore ?? 0) {
                                    return true
                                } else {
                                    return false
                                }
                            }
                        }) {
                            if let matchScore = matched.matchScore {
                                logMatchScore = matchScore
                            }
                            if let peopleId = matched.peopleid {
                                logPeopleId = peopleId
                            }
                            if let uniqueId = matched.uniqueId {
                                logUniqueId = uniqueId
                            }
                            logPeopleName = "\(matched.firstname ?? "") \(matched.lastname ?? "")"
                            logUserType = matched.usertype ?? ""
                            if let listIdArray = matched.listid {
                                listId = listIdArray.joined(separator: ",")
                            }
                        }
                    }
                } else {
                    if let eventId = eventIdDetail.eventid, self.data.count > 0 {
                        if let matched = self.data.max(by: { first, second in
                            if let peopleEventId = second.eventID, eventId == peopleEventId {
                                return true
                            } else if let peopleEventId = first.eventID, eventId == peopleEventId {
                                return false
                            } else {
                                if (first.matchScore ?? 0) < (second.matchScore ?? 0) {
                                    return true
                                } else {
                                    return false
                                }
                            }
                        }) {
                            if let peopleEventId = matched.eventID, (eventId == peopleEventId && (matched.isactive ?? true)) {
                                if Utilities.shared.isMQTTEnabled() {
                                    MQTTManager.shared().publish(topic: MQTT.PublisherTopic, message: MQTT.OnCommand)
                                }
                                scanType = .success
                                self.statusView.backgroundColor = .successScanColor
                                if let peopleSpecificMsg = kioskDetail.peoplespecificmsg, let welComeMsg = matched.welcomemsg, peopleSpecificMsg, welComeMsg != "" {
                                    message = welComeMsg
                                } else if let scanSuccess = kioskDetail.scansuccess, scanSuccess != "" {
                                    message = "\(Message.Welcome) \(matched.firstname ?? "") \(matched.lastname ?? "")\n\n\(scanSuccess)"
                                } else {
                                    message = Message.AuthorisedPerson
                                }
                                self.nameLabel.textAlignment = .center
                                self.nameLabel.text = message
                            } else {
                                scanType = .unauthorized
                                self.statusView.backgroundColor = .failedScanColor
                                if let scanFailure = kioskDetail.scanfailure, scanFailure != "" {
                                    message = scanFailure
                                } else {
                                    message = Message.UnauthorisedPerson
                                }
                                self.nameLabel.textAlignment = .center
                                self.nameLabel.text = message
                            }
                            if let matchScore = matched.matchScore {
                                logMatchScore = matchScore
                            }
                            if let peopleId = matched.peopleid {
                                logPeopleId = peopleId
                            }
                            if let uniqueId = matched.uniqueId {
                                logUniqueId = uniqueId
                            }
                            logPeopleName = "\(matched.firstname ?? "") \(matched.lastname ?? "")"
                            logUserType = matched.usertype ?? ""
                            if let listIdArray = matched.listid {
                                listId = listIdArray.joined(separator: ",")
                            }
                        } else {
                            scanType = .unauthorized
                            self.statusView.backgroundColor = .failedScanColor
                            if let scanFailure = kioskDetail.scanfailure, scanFailure != "" {
                                message = scanFailure
                            } else {
                                message = Message.UnauthorisedPerson
                            }
                            self.nameLabel.textAlignment = .center
                            self.nameLabel.text = message
                        }
                    } else {
                        scanType = .unauthorized
                        self.statusView.backgroundColor = .failedScanColor
                        if let scanFailure = kioskDetail.scanfailure, scanFailure != "" {
                            message = scanFailure
                        } else {
                            message = Message.UnauthorisedPerson
                        }
                        self.nameLabel.textAlignment = .center
                        self.nameLabel.text = message
                    }
                }
            } else {
                scanType = .unauthorized
                self.statusView.backgroundColor = .failedScanColor
                message = Message.UnauthorisedPerson
                self.nameLabel.textAlignment = .center
                self.nameLabel.text = message
            }
        }
        
        self.scanType = scanType
        self.playScanSound(scanType)
        appDelegate.saveLogs(imageBase64: self.imageBase64, message: message.condenseWhitespace(), peopleId: logPeopleId, peopleName: logPeopleName, matchScore: logMatchScore, apiResponse: apiResponse, listId: listId, eventId: logEventId, deviceId: logDeviceId, eventName: logEventName, scanType: scanType, userType: logUserType)
        
        if logUniqueId != "" {
            let isSuccess = (scanType == .success ? "1" : "0")
            let location =  UserDefaultsServices.shared.getSelectedLocation()
            let day =  UserDefaultsServices.shared.getSelectedDay()
            appDelegate.authenticationSaveData(uniqueId: logUniqueId, isSuccess: isSuccess, locationGate: location, day: day)
        }
        
        self.autoDismiss()
    }
    
    func playScanSound(_ scanType: ScanType) {
        if UserDefaultsServices.shared.isScanSound() {
            let scanSound: ScanSound?
            switch scanType {
            case .success:
                scanSound = ScanSound(name: "successSound", type: "mp3")
            case .livenessFailed, .futureEvent, .expiredEvent, .unauthorized:
                scanSound = ScanSound(name: "failedSound", type: "mp3")
            }
            if let scanSound = scanSound {
                scanSound.play()
            }
        }
    }
    
    func autoDismiss() {
        if scanType == .success {
            if !UserDefaultsServices.shared.isTapScanSuccess() {
                let delay = UserDefaultsServices.shared.getNextScanDelay()
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(Int(delay))) {
                    if self.isPresented == false {
                        self.dismiss(animated: true)
                    }
                }
            }
        } else {
            if !UserDefaultsServices.shared.isTapScanFailure() {
                let delay = UserDefaultsServices.shared.getNextScanDelay()
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(Int(delay))) {
                    if self.isPresented == false {
                        self.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
    @IBAction func menuAction(_ sender: Any) {
        if let leftSideMenu = self.getViewController(storyboard: Storyboard.sideMenu, id: "LeftMenuNavigationController") as? SideMenuNavigationController {
            Utilities.shared.sideMenuSettings(leftSideMenu: leftSideMenu)
            self.present(leftSideMenu, animated: true)
        }
    }
    
    @IBAction func dismissAction(_ sender: Any) {
        if let scanType = self.scanType {
            if scanType == .success {
                if UserDefaultsServices.shared.isTapScanSuccess() {
                    self.dismiss(animated: true)
                }
            } else {
                if UserDefaultsServices.shared.isTapScanFailure() {
                    self.dismiss(animated: true)
                }
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ResultViewController: SideMenuNavigationControllerDelegate {
    func sideMenuWillAppear(menu: SideMenuNavigationController, animated: Bool) {
        self.isPresented = true
    }
    
    func sideMenuDidDisappear(menu: SideMenuNavigationController, animated: Bool) {
        if self.isPresented {
            self.isPresented = false
            self.autoDismiss()
        }
    }
}
