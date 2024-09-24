//
//  ControlCenterViewModel.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 08/04/24.
//

import Foundation
import Alamofire

class ControlCenterViewModel: NSObject {
    func getPeopleData(deviceMac: String, isLoader: Bool, completion:@escaping(PeopleDataModel?) -> Void) {
        let headers: HTTPHeaders = [HeaderValue.Authorization: "Bearer \(UserDefaultsServices.shared.getAccessToken())"]
        let param = ["devicemac": deviceMac, "timestamp": "\(UserDefaultsServices.shared.getLastSyncTimeStamp())"] as! [String: Any]  
//        debugPrint(API.peopleData)
//        debugPrint(headers)
//        debugPrint(param)
        
        let requestHelper = RequestHelper(url: API.peopleData, method: .post, parameters: param, encoding: JSONEncoding.default, headers: headers)
        APIManager.sharedInstance.request(with: requestHelper, isLoader: isLoader) { response in
            if response.error == nil {
                if let responseDa = response.responseData {
                    let json = try? JSONDecoder().decode(PeopleDataModel.self, from: responseDa)
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
