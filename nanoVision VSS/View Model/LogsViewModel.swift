//
//  LogsViewModel.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 17/04/24.
//

import Foundation
import Alamofire

class LogsViewModel: NSObject {
    
    // MARK: - Get Logs Api integration
    func getLogsApi(currentTimestamp: String, deviceId: Int, isLoader: Bool, completion:@escaping(LogsModel?) -> Void) {
        
        let headers: HTTPHeaders = [HeaderValue.Authorization: "Bearer \(UserDefaultsServices.shared.getAccessToken())", HeaderValue.ContentType: HeaderValue.ContentValue]
        
        let param = ["current_timestamp": currentTimestamp,
                     "deviceid": deviceId
        ] as! [String: Any]
        
        debugPrint(API.getLogs)
        debugPrint(headers)
        debugPrint(param)
        
        let requestHelper = RequestHelper(url: API.getLogs, method: .post, parameters: param, encoding: JSONEncoding.default, headers: headers)
        APIManager.sharedInstance.request(with: requestHelper, isLoader: isLoader) { response in
            if response.error == nil {
                if let responseDa = response.responseData {
                    let json = try? JSONDecoder().decode(LogsModel.self, from: responseDa)
                    completion(json)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Create Logs Api integration
    func createLogsApi(logs: [Logs], isLoader: Bool, completion:@escaping(CreateLogsModel?) -> Void) {
        
        let headers: HTTPHeaders = [HeaderValue.Authorization: "Bearer \(UserDefaultsServices.shared.getAccessToken())", HeaderValue.ContentType: HeaderValue.ContentValue]
        
        var param:[[String: Any]] = []
        for log in logs {
            if log.eventid != 0 && log.deviceid != 0 {
                var data = ["eventid": log.eventid,
                            "deviceid": log.deviceid,
                            "confidencescore": log.confidencescore,
                            "message": log.message ?? "",
                            "devicetype": log.devicetype ?? "",
                            "apiresponse": log.apiresponse ?? "",
                            "logid": log.applogid
                ] as! [String: Any]
                if let base64Data = log.base64String {
                    data["base64string"] = base64Data.toBase64String()
                }
                if let createddate = log.createddate, createddate != "" {
                    data["createddate"] = createddate
                }
                if log.peopleid != 0 {
                    data["peopleid"] = log.peopleid
                }
                if let listId = log.listid, listId != "" {
                    data["list_id"] = listId
                }
                param.append(data)
            }
        }
        
        
//        debugPrint(API.createLogs)
//        debugPrint(headers)
//        debugPrint(param)
        
        let data = try! JSONSerialization.data(withJSONObject: param, options: .prettyPrinted)
        let body : ParameterEncoding = MyCustomEncoding(data: data)
        
        let requestHelper = RequestHelper(url: API.createLogs, method: .post, encoding: body, headers: headers)
        APIManager.sharedInstance.request(with: requestHelper, isLoader: isLoader) { response in
            if response.error == nil {
                if let responseDa = response.responseData {
                    let json = try? JSONDecoder().decode(CreateLogsModel.self, from: responseDa)
                    completion(json)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }

}
