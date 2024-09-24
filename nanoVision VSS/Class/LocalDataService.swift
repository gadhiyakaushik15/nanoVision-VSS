//
//  LocalDataService.swift
//  Paravision
//
//  Created by Kaushik Gadhiya on 30/01/24.
//

import Foundation
import CoreData
import AppleArchive
import System
import SSZipArchive
import TabularData

final class LocalDataService {
    static var shared = LocalDataService()
    private var timer: Timer?
    private var isSyncPeoples = false
    private var isSyncLogs = false
    var syncCompleted: (() -> Void)?
    private var lastSyncTimeStamp = ""
    
    func syncData() {
        if self.timer == nil {
            self.timer = Timer.scheduledTimer(timeInterval: Constants.AutoSyncTime, target: self, selector: #selector(self.starSyncData), userInfo: nil, repeats: true)
        }
    }
    
    func stopTimer() {
        if self.timer != nil {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    @objc func starSyncData(isSyncLogs: Bool = false) {
        if APIManager.isConnectedToInternet() {
            if !self.isSyncPeoples {
                self.getDeviceStatus(isSyncLogs: isSyncLogs)
            } else {
                if isSyncLogs {
                    self.isSyncLogs = isSyncLogs
                }
            }
        }
    }   
    
    func getDeviceStatus(isSyncLogs: Bool = false) {
        self.isSyncPeoples = true
        self.isSyncLogs = isSyncLogs
        LoginViewModel().getDeviceStatus(deviceMac: KeychainServices.shared.getDeviceMac(), isLoader: false) { data in
            if let data = data, let status = data.status, status.lowercased() == APIStatus.Success {
                if let results = data.results, let devicesDetailsArray = results.devicesDetails, let devicesDetails = devicesDetailsArray.first {
                    UserDefaultsServices.shared.saveDevicesDetails(devicesDetails: devicesDetails)
                    OfflineDevicesDetails.shared.devicesDetails = devicesDetails
                }
            }
            if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails, let deviceStatus =  devicesDetails.deviceStatus {
                if deviceStatus.lowercased() == DeviceStatus.Approved {
                    if let isDefaultKioskAssigned = devicesDetails.isDefaultKioskAssigned, let isDefaultEventAssigned = devicesDetails.isDefaultEventAssigned, (isDefaultKioskAssigned && isDefaultEventAssigned) {
                        if Utilities.shared.isMQTTEnabled() {
                            if Utilities.shared.getAssignedRelay() != nil {
                                self.getPeople()
                            } else {
                                DispatchQueue.main.async() {
                                    Utilities.shared.dismissSVProgressHUD()
                                    if let topPresentedController = Utilities.shared.getTopPresentedController(), let controller = topPresentedController.getViewController(storyboard: Storyboard.deviceStatus, id: "DeviceStatusViewController") as? DeviceStatusViewController {
                                        topPresentedController.present(controller, animated: true) {
                                            LocalDataService.shared.stopTimer()
                                            if MQTTAppState.shared().appConnectionState.isConnected {
                                                MQTTManager.shared().disconnect()
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            self.getPeople()
                        }
                    } else {
                        DispatchQueue.main.async() {
                            Utilities.shared.dismissSVProgressHUD()
                            if let topPresentedController = Utilities.shared.getTopPresentedController(), let controller = topPresentedController.getViewController(storyboard: Storyboard.deviceStatus, id: "DeviceStatusViewController") as? DeviceStatusViewController {
                                topPresentedController.present(controller, animated: true) {
                                    LocalDataService.shared.stopTimer()
                                    if Utilities.shared.isMQTTEnabled() {
                                        if MQTTAppState.shared().appConnectionState.isConnected {
                                            MQTTManager.shared().disconnect()
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async() {
                        Utilities.shared.dismissSVProgressHUD()
                        if let topPresentedController = Utilities.shared.getTopPresentedController(), let controller = topPresentedController.getViewController(storyboard: Storyboard.deviceStatus, id: "DeviceStatusViewController") as? DeviceStatusViewController {
                            topPresentedController.present(controller, animated: true) {
                                LocalDataService.shared.stopTimer()
                                if Utilities.shared.isMQTTEnabled() {
                                    if MQTTAppState.shared().appConnectionState.isConnected {
                                        MQTTManager.shared().disconnect()
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                self.getPeople()
            }
        }
    }
    
    func getPeople() {
        self.lastSyncTimeStamp = Utilities.shared.convertDateToString(date: Date(), requiredFormat: "yyyy-MM-dd HH:mm:ss.SSS")
        ControlCenterViewModel().getPeopleData(deviceMac: KeychainServices.shared.getDeviceMac(), isLoader: false) { data in
            if let data = data {
                if let status = data.status, status.lowercased() == APIStatus.Success {
                    if let result = data.result, let peopleInformation = result.peopleInformation {
                        if peopleInformation != "" {
                            self.storePeopleCSV(with: peopleInformation)
                        } else {
                            self.syncCompletedMethod()
                        }
                    } else {
                        self.fetchPeoples()
                    }
                } else {
                    self.fetchPeoples()
                }
            } else {
                self.fetchPeoples()
            }
        }
    }
    
    func storePeopleCSV(with base64String: String) {
        if let base64Data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) {
            do {
                let documentsPath = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let zipFilePath = documentsPath.appendingPathComponent(Constants.ZipFileName).path
                let csvFolderPath = documentsPath.appendingPathComponent(Constants.PeopleDataFolderName).path
                if FileManager.default.fileExists(atPath: zipFilePath) {
                    self.deleteZip()
                }
                FileManager.default.createFile(atPath: zipFilePath, contents: base64Data)
//                try SSZipArchive.unzipFile(atPath: zipFilePath, toDestination: csvFolderPath, overwrite: true, password: nil)
                SSZipArchive.unzipFile(atPath: zipFilePath, toDestination: csvFolderPath, overwrite: true, password: nil) { _, _, _, _ in
                    
                } completionHandler: { path, succeeded, error in
                    if succeeded {
                        self.deleteZip()
                    }
                }
            } catch let failedError {
                debugPrint("Failed to write the file data due to \(failedError.localizedDescription)")
            }
        }
        self.fetchPeoples()
    }
    
    func deleteZip() {
        do {
            let documentsPath = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let zipFilePath = documentsPath.appendingPathComponent(Constants.ZipFileName).path
            if FileManager.default.fileExists(atPath: zipFilePath) {
                try FileManager.default.removeItem(atPath: zipFilePath)
            }
        } catch let failedError {
            debugPrint("Failed to delete the file data due to \(failedError.localizedDescription)")
        }
    }
    
    func deleteCSV() {
        do {
            let documentsPath = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let csvUrl = documentsPath.appendingPathComponent("\(Constants.PeopleDataFolderName)/\(Constants.CsvFileName)").path
            if FileManager.default.fileExists(atPath: csvUrl) {
                try FileManager.default.removeItem(atPath: csvUrl)
            }
        } catch let failedError {
            debugPrint("Failed to delete the file data due to \(failedError.localizedDescription)")
        }
    }
    
    func deletePeopleCSV() {
        do {
            let documentsPath = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let csvUrl = documentsPath.appendingPathComponent("\(Constants.PeopleDataFolderName)/\(Constants.PeopleCsvFileName)").path
            if FileManager.default.fileExists(atPath: csvUrl) {
                try FileManager.default.removeItem(atPath: csvUrl)
            }
        } catch let failedError {
            debugPrint("Failed to delete the file data due to \(failedError.localizedDescription)")
        }
    }
    
    func fetchPeoples() {
        do {
            let documentsPath = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let csvUrl = documentsPath.appendingPathComponent("\(Constants.PeopleDataFolderName)/\(Constants.CsvFileName)")
            let peopleCsvUrl = documentsPath.appendingPathComponent("\(Constants.PeopleDataFolderName)/\(Constants.PeopleCsvFileName)")
            if FileManager.default.fileExists(atPath: csvUrl.path) {
                var peoples = [PeoplesModel]()
                let result = try DataFrame(contentsOfCSVFile: csvUrl)
                if FileManager.default.fileExists(atPath: peopleCsvUrl.path) {
                    if UserDefaultsServices.shared.getLastSyncTimeStamp() == Constants.DefaultLastSyncTimeStamp {
                        self.deletePeopleCSV()
                        try result.writeCSV(to: peopleCsvUrl)
                    } else {
                        peoples = OfflinePeoples.shared.peoples
                        var peopleResult = try DataFrame(contentsOfCSVFile: peopleCsvUrl)
                        peopleResult.append(result)
                        self.deletePeopleCSV()
                        try peopleResult.writeCSV(to: peopleCsvUrl)
                    }
                } else {
                    try result.writeCSV(to: peopleCsvUrl)
                }
                for row in result.rows {
                    if row.count >= 18 {
                        var peopleId: Int?
                        if let value = row[0] as? Int {
                            peopleId = value
                        }
                        
                        var firstName: String?
                        if let value = row[1] as? String {
                            firstName = value
                        }
                        
                        var middleName: String?
                        if let value = row[2] as? String {
                            middleName = value
                        }
                        
                        var lastName: String?
                        if let value = row[3] as? String {
                            lastName = value
                        }
                        
                        var email: String?
                        if let value = row[4] as? String {
                            email = value
                        }
                        
                        var phone: Int?
                        if let value = row[5] as? Int {
                            phone = value
                        } else if let value = row[5] as? String, let intPhone = Int(value) {
                            phone = intPhone
                        }
                        
                        var additionalDetails: String?
                        if let value = row[6] as? String {
                            additionalDetails = value
                        }
                        
                        var listIdString: String = ""
                        if let value = row[7] as? String {
                            listIdString = value
                        }
                        listIdString = listIdString.replacingOccurrences(of: "[", with: "")
                        listIdString = listIdString.replacingOccurrences(of: "]", with: "")
                        let listIdStringArray = listIdString.components(separatedBy: ",")
                        
                        let isActive = ((row[8] as? Bool) ?? true)
                        
                        var embeddedImage: [Float]?
                        if let value = row[9] as? String {
                            embeddedImage = value.split(separator: ",").compactMap { Float($0)}
                        }
                        
                        var eventId: Int?
                        if let value = row[10] as? Int {
                            eventId = value
                        }
                        
                        var locationId: Int?
                        if let value = row[11] as? Int {
                            locationId = value
                        }
                        
                        let isDelete = ((row[12] as? Bool) ?? false)
                        
                        var welcomeMsg: String?
                        if let value = row[13] as? String {
                            welcomeMsg = value
                        }
                        
                        var qrcode: String?
                        if let value = row[14] as? String {
                            qrcode = value
                        }
                        
                        var userType: String?
                        if let value = row[15] as? String {
                            userType = value
                        }
                        
                        var lastModifiedDate: String?
                        if let value = row[16] as? String {
                            lastModifiedDate = value
                        }
                        
                        var uniqueId: String?
                        if let value = row[17] as? String {
                            uniqueId = value
                        }
                        
                        peoples.append(PeoplesModel(peopleid: peopleId, firstname: firstName, middlename: middleName, lastname: lastName, email: email, phone: phone, additionaldetails: additionalDetails, listid: listIdStringArray, isactive: isActive, embeddedimage: embeddedImage, eventID: eventId, locationid: locationId, isdelete: isDelete, welcomemsg: welcomeMsg, qrcode: qrcode, usertype: userType, lastmodifieddate: lastModifiedDate, uniqueId: uniqueId))
                    }
                }
                debugPrint("Peoples Old Count = \(OfflinePeoples.shared.peoples.count)")
                OfflinePeoples.shared.peoples = peoples
                debugPrint("Peoples New Count = \(OfflinePeoples.shared.peoples.count)")
                UserDefaultsServices.shared.saveLastSyncTimeStamp(value: self.lastSyncTimeStamp)
            } else {
                var peoples = [PeoplesModel]()
                if FileManager.default.fileExists(atPath: peopleCsvUrl.path) {
                    let peopleResult = try DataFrame(contentsOfCSVFile: peopleCsvUrl)
                    for row in peopleResult.rows {
                        if row.count >= 18 {
                            var peopleId: Int?
                            if let value = row[0] as? Int {
                                peopleId = value
                            }
                            
                            var firstName: String?
                            if let value = row[1] as? String {
                                firstName = value
                            }
                            
                            var middleName: String?
                            if let value = row[2] as? String {
                                middleName = value
                            }
                            
                            var lastName: String?
                            if let value = row[3] as? String {
                                lastName = value
                            }
                            
                            var email: String?
                            if let value = row[4] as? String {
                                email = value
                            }
                            
                            var phone: Int?
                            if let value = row[5] as? Int {
                                phone = value
                            } else if let value = row[5] as? String, let intPhone = Int(value) {
                                phone = intPhone
                            }
                            
                            var additionalDetails: String?
                            if let value = row[6] as? String {
                                additionalDetails = value
                            }
                            
                            var listIdString: String = ""
                            if let value = row[7] as? String {
                                listIdString = value
                            }
                            listIdString = listIdString.replacingOccurrences(of: "[", with: "")
                            listIdString = listIdString.replacingOccurrences(of: "]", with: "")
                            let listIdStringArray = listIdString.components(separatedBy: ",")
                            
                            let isActive = ((row[8] as? Bool) ?? true)
                            
                            var embeddedImage: [Float]?
                            if let value = row[9] as? String {
                                embeddedImage = value.split(separator: ",").compactMap { Float($0)}
                            }
                            
                            var eventId: Int?
                            if let value = row[10] as? Int {
                                eventId = value
                            }
                            
                            var locationId: Int?
                            if let value = row[11] as? Int {
                                locationId = value
                            }
                            
                            let isDelete = ((row[12] as? Bool) ?? false)
                            
                            var welcomeMsg: String?
                            if let value = row[13] as? String {
                                welcomeMsg = value
                            }
                            
                            var qrcode: String?
                            if let value = row[14] as? String {
                                qrcode = value
                            }
                            
                            var userType: String?
                            if let value = row[15] as? String {
                                userType = value
                            }
                            
                            var lastModifiedDate: String?
                            if let value = row[16] as? String {
                                lastModifiedDate = value
                            }
                            
                            var uniqueId: String?
                            if let value = row[17] as? String {
                                uniqueId = value
                            }
                            
                            peoples.append(PeoplesModel(peopleid: peopleId, firstname: firstName, middlename: middleName, lastname: lastName, email: email, phone: phone, additionaldetails: additionalDetails, listid: listIdStringArray, isactive: isActive, embeddedimage: embeddedImage, eventID: eventId, locationid: locationId, isdelete: isDelete, welcomemsg: welcomeMsg, qrcode: qrcode, usertype: userType, lastmodifieddate: lastModifiedDate, uniqueId: uniqueId))
                        }
                    }
                }
                debugPrint("Peoples Old Count = \(OfflinePeoples.shared.peoples.count)")
                OfflinePeoples.shared.peoples = peoples
                debugPrint("Peoples New Count = \(OfflinePeoples.shared.peoples.count)")
            }
            self.deleteCSV()
        } catch let failedError {
            debugPrint("Failed to write the file data due to \(failedError.localizedDescription)")
        }
        self.syncCompletedMethod()
    }
    
    func syncCompletedMethod() {
        if self.isSyncLogs {
            self.createLogs()
        } else {
            if let syncCompleted = self.syncCompleted {
                self.isSyncPeoples = false
                let syncTime = Utilities.shared.convertNSDateToStringFormat(date: Date(), requiredFormat: "dd/MM/yyyy HH:mm:ss")
                UserDefaultsServices.shared.savePeoplesLastSyncDate(date: syncTime)
                syncCompleted()
            }
        }
    }
    
    func saveLogs(logs: [LogsResult]) {
        appDelegate.enqueue { manageObjContext in
            do {
                if let codableContext = CodingUserInfoKey.init(rawValue: "context") {
                    let decoder = JSONDecoder()
                    decoder.userInfo[codableContext] = manageObjContext
                    let data = try JSONEncoder().encode(logs)
                    _ = try decoder.decode([Logs].self, from: data)
                    appDelegate.saveContext(manageObjContext)
                }
            } catch let error {
                debugPrint("Error ->\(error.localizedDescription)")
            }
        }
    }
    
    func saveLogs(logs: [Logs]) {
        appDelegate.enqueue { manageObjContext in
            do {
                if let codableContext = CodingUserInfoKey.init(rawValue: "context") {
                    let decoder = JSONDecoder()
                    decoder.userInfo[codableContext] = manageObjContext
                    let data = try JSONEncoder().encode(logs)
                    _ = try decoder.decode([Logs].self, from: data)
                    appDelegate.saveContext(manageObjContext)
                }
            } catch let error {
                debugPrint("Error ->\(error.localizedDescription)")
            }
        }
    }
    
//    func deleteLogs() {
//        appDelegate.enqueue { manageObjContext in
//            if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails, let devices = devicesDetails.device, let device = devices.first, let deviceId = device.deviceid {
//                for log in self.fetchLogs() {
//                    if log.deviceid != 0 && log.deviceid != deviceId {
//                        do {
//                            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Logs")
//                            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//                            try manageObjContext.execute(deleteRequest)
//                            break
//                        } catch let error {
//                            debugPrint("Error ->\(error.localizedDescription)")
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    func updateLogs(insertedIds: [Int]) {
        appDelegate.enqueue { manageObjContext in
            for insertedId in insertedIds {
                do {
                    let fetchRequest =  Logs.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "applogid = %d", insertedId)
                    let logs = try manageObjContext.fetch(fetchRequest)
                    for log in logs {
                        log.iscreated = true
                    }
                    appDelegate.saveContext(manageObjContext)
                } catch let error {
                    debugPrint("Error ->\(error.localizedDescription)")
                }
            }
        }
    }
    
    func fetchLogs(isSelectedEventLog: Bool = true, completion: @escaping ([Logs]) -> Void) {
        let fetchRequest = Logs.fetchRequest()
//        fetchRequest.returnsObjectsAsFaults = false
//        let sortDescriptor = NSSortDescriptor(key: "applogid", ascending: false)
//        fetchRequest.sortDescriptors = [sortDescriptor]
        let manageObjContext = appDelegate.persistentContainer.viewContext
        DispatchQueue.global(qos: .background).async {
            do {
                var logs = try manageObjContext.fetch(fetchRequest)
                logs = logs.sorted(by: {$0.applogid > $1.applogid})
                if isSelectedEventLog {
                    logs = logs.filter({ log in
                        if let deviceId = Utilities.shared.getDeviceId(), let eventId = Utilities.shared.getSelectedEventId(), (log.deviceid == deviceId && log.eventid == eventId) {
                            return true
                        } else {
                            return false
                        }
                    })
                }
                debugPrint("Logs Count = \(logs.count)")
                DispatchQueue.main.async {
                    completion(logs)
                }
            } catch let error {
                debugPrint(error)
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    func createLogs(isSync: Bool = true) {
        self.fetchLogs(isSelectedEventLog: false) { allLogs in
            let remainLogs = allLogs.filter { $0.iscreated == false}
            if remainLogs.count > 0 {
                debugPrint("Logs Creating Count = \(remainLogs.count)")
                LogsViewModel().createLogsApi(logs: remainLogs, isLoader: false) { data in
                    if let data = data, let status = data.status, let result = data.result, (status == APIStatus.Success || status == APIStatus.PartialSuccess) {
                        debugPrint("\(data.message ?? "Logs Created")")
                        if let insertedIds = result.insertedIDS, insertedIds.count > 0 {
                            self.updateLogs(insertedIds: insertedIds)
                        }
                    }
                    if let syncCompleted = self.syncCompleted, isSync {
                        self.isSyncPeoples = false
                        self.isSyncLogs = false
                        let syncTime = Utilities.shared.convertNSDateToStringFormat(date: Date(), requiredFormat: "dd/MM/yyyy HH:mm:ss")
                        UserDefaultsServices.shared.savePeoplesLastSyncDate(date: syncTime)
                        UserDefaultsServices.shared.saveLogsLastSyncDate(date: syncTime)
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1)  {
                            syncCompleted()
                        }
                    }
                }
            } else {
                if let syncCompleted = self.syncCompleted, isSync {
                    self.isSyncPeoples = false
                    self.isSyncLogs = false
                    let syncTime = Utilities.shared.convertNSDateToStringFormat(date: Date(), requiredFormat: "dd/MM/yyyy HH:mm:ss")
                    UserDefaultsServices.shared.savePeoplesLastSyncDate(date: syncTime)
                    syncCompleted()
                }
            }
        }
    }
}
