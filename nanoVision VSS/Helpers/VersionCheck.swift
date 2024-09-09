//
//  VersionCheck.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 15/05/24.
//

import Foundation
import Alamofire

class VersionCheck {
    public static let shared = VersionCheck()
    func isUpdateAvailable(callback: @escaping (Bool, String, String)->Void) {
        if APIManager.isConnectedToInternet() {
            let bundleId = Bundle.main.infoDictionary!["CFBundleIdentifier"] as! String
            AF.request("https://itunes.apple.com/lookup?bundleId=\(bundleId)").responseJSON { response in
                var isUpdateAvailable = false
                var version = ""
                var appStoreUrl = ""
                switch response.result {
                case .success(let value):
                    if let json = value as? NSDictionary, let results = json["results"] as? NSArray, let result = results.firstObject, let data = result as? NSDictionary , let versionStore = data["version"] as? String, let trackViewUrl = data["trackViewUrl"] as? String, let currentVersionReleaseDateString = data["currentVersionReleaseDate"] as? String, let currentVersionReleaseDate = Utilities.shared.convertStringToNSDateFormat(date: currentVersionReleaseDateString, currentFormat: "yyyy-MM-dd'T'HH:mm:ssZ"), let versionLocal = Bundle.main.version {
                        appStoreUrl = trackViewUrl
                        version = versionStore
                        let arrayStore = versionStore.split(separator: ".").compactMap { Int($0) }
                        let arrayLocal = versionLocal.split(separator: ".").compactMap { Int($0) }
                        
                        if arrayLocal.count != arrayStore.count {
                            isUpdateAvailable = true
                        } else {
                            for (localSegment, storeSegment) in zip(arrayLocal, arrayStore) {
                                if localSegment < storeSegment {
                                    isUpdateAvailable = true
                                    break
                                }
                            }
                        }
                    }
                case .failure(_):
                    break
                }
                callback(isUpdateAvailable, version, appStoreUrl)
            }
        } else {
            callback(false, "", "")
        }
    }
}
