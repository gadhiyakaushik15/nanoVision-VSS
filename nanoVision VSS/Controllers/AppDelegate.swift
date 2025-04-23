//
//  AppDelegate.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 03/04/24.
//

import UIKit
import CoreData
import IQKeyboardManagerSwift

let appDelegate = UIApplication.shared.delegate as! AppDelegate

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let persistentContainerQueue = OperationQueue()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // TODO: UI Configuration
        self.updateUIConfig()
        
        // TODO: Init Paravision
        ParavisionServices.shared.initEstimator {}
        
        self.persistentContainerQueue.maxConcurrentOperationCount = 1
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if UserDefaultsServices.shared.isLogin() {
            LocalDataService.shared.stopTimer()
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        if UserDefaultsServices.shared.isLogin() {
            if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails, let deviceStatus =  devicesDetails.deviceStatus {
                if deviceStatus.lowercased() == DeviceStatus.Approved {
                    if let isDefaultKioskAssigned = devicesDetails.isDefaultKioskAssigned, let isDefaultEventAssigned = devicesDetails.isDefaultEventAssigned, (isDefaultKioskAssigned && isDefaultEventAssigned) {
                        LocalDataService.shared.getDeviceStatus()
                        LocalDataService.shared.syncData()
                    }
                }
            }
            if let topPresentedController = Utilities.shared.getTopPresentedController() {
                if topPresentedController.isKind(of: CameraViewController.self) {
                    if let cameraViewController = topPresentedController as? CameraViewController {
                        cameraViewController.startSession()
                    }
                } else if topPresentedController.isKind(of: SelfieCameraViewController.self) {
                    if let selfieCameraViewController = topPresentedController as? SelfieCameraViewController {
                        selfieCameraViewController.startSession()
                    }
                }
            }
        }
        self.checkVersion { status in }
    }
    
    //MARK: - Update UI Config
    func updateUIConfig(){
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside =  false
        if Utilities.shared.isPadDevice() {
            IQKeyboardManager.shared.keyboardDistance = 200
        } else {
            IQKeyboardManager.shared.keyboardDistance = 100
        }
    }
    
    func checkVersion(callback: @escaping (Bool)->Void) {
        VersionCheck.shared.isUpdateAvailable { status, version, appStoreUrl   in
            if status {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                    if let topPresentedController = Utilities.shared.getTopPresentedController() {
                        let alert = UIAlertController(title: Message.UpdateAvailable,
                                                      message: String(format: Message.UpdateMessage, (Bundle.main.displayName ?? ""), version),
                                                      preferredStyle: .alert)
                        let updateAction = UIAlertAction(title: Message.Update, style: .default) { (action) in
                            if let url = URL(string: appStoreUrl),  UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        }
                        alert.addAction(updateAction)
                        topPresentedController.present(alert, animated: true)
                        callback(true)
                    } else {
                        callback(false)
                    }
                }
            } else {
                callback(false)
            }
        }
    }

    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "nanoVision")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                debugPrint("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support
    func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                debugPrint("Error ->\(error.localizedDescription)")
            }
        }
    }
    
    func enqueue(block: @escaping (_ context: NSManagedObjectContext) -> Void) {
      persistentContainerQueue.addOperation(){
        let context: NSManagedObjectContext = self.persistentContainer.newBackgroundContext()
          context.perform {
            block(context)
          }
        }
    }
    
    // MARK: - Save logs
    func saveLogs(imageBase64: Data?, message: String, peopleId: Int, peopleName: String, matchScore: Int, apiResponse: String, listId: String, eventId: Int?, deviceId: Int?, eventName: String, scanType: ScanType, userType: String) {
        
        var logEventId = eventId
        var logDeviceId = deviceId
        var logEventName = eventName
        
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
        
        let logCreatedDate = Utilities.shared.convertNSDateToStringFormat(date: Date(), requiredFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
        
        var appLogId = 1
        if let id = Int(KeychainServices.shared.getAppLogId()) {
            appLogId = id + 1
        }
        KeychainServices.shared.saveAppLogId(appLogId: "\(appLogId)")
        let log = LogsResult(base64String: imageBase64, message: message, createddate: logCreatedDate, devicetype: Constants.DeviceType, peopleid: peopleId, confidencescore: matchScore, eventid: logEventId, apiresponse: apiResponse, logid: nil, deviceid: logDeviceId, applogid: appLogId, listid: listId, iscreated: false, eventname: logEventName, peoplename: peopleName, scantype: scanType.rawValue, usertype: userType)
        
        LocalDataService.shared.saveLogs(logs: [log])
        
        debugPrint("App Log Id = \(appLogId)")
    }
}

