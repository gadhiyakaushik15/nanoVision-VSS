//
//  ViableSoftModel.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 08/09/24.
//

import Foundation
import Alamofire

class ViableSoftModel: NSObject {
    
    func getDays( isLoader: Bool, completion:@escaping([DayModel]?) -> Void) {
        
        let headers: HTTPHeaders = [HeaderValue.ApiKey: Constants.ViableSoftApiKey, HeaderValue.ContentType: HeaderValue.ContentValue]
        
//        debugPrint(API.day)
//        debugPrint(headers)
        
        let requestHelper = RequestHelper(url: API.day, method: .get, headers: headers)
        APIManager.sharedInstance.request(with: requestHelper, isLoader: isLoader) { response in
            if response.error == nil {
                if let responseDa = response.responseData {
                    let json = try? JSONDecoder().decode([DayModel].self, from: responseDa)
                    completion(json)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    func getLocationTable( isLoader: Bool, completion:@escaping([LocationModel]?) -> Void) {
        
        let headers: HTTPHeaders = [HeaderValue.ApiKey: Constants.ViableSoftApiKey, HeaderValue.ContentType: HeaderValue.ContentValue]
        
//        debugPrint(API.locationTable)
//        debugPrint(headers)
        
        let requestHelper = RequestHelper(url: API.locationTable, method: .get, headers: headers)
        APIManager.sharedInstance.request(with: requestHelper, isLoader: isLoader) { response in
            if response.error == nil {
                if let responseDa = response.responseData {
                    let json = try? JSONDecoder().decode([LocationModel].self, from: responseDa)
                    completion(json)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    func authenticationSaveData(uniqueId: String, isSuccess: String, locationGate: String, day: String, isLoader: Bool, completion : ((_ status : Bool, _ message: String) -> Void)?) {
        
        let headers: HTTPHeaders = [HeaderValue.ApiKey: Constants.ViableSoftApiKey, HeaderValue.ContentType: HeaderValue.ContentValue]
        
        var param:[[String: Any]] = []
        let paramData = ["REGID": uniqueId,
                         "ACESSALLOW": isSuccess,
                         "LocationGate": locationGate,
                         "DAYID": day
        ] as! [String: Any]
        param.append(paramData)
        
//        debugPrint(API.authenticationSaveData)
//        debugPrint(headers)
//        debugPrint(param)
        
        let data = try! JSONSerialization.data(withJSONObject: param, options: .prettyPrinted)
        let body : ParameterEncoding = MyCustomEncoding(data: data)
        
        let requestHelper = RequestHelper(url: API.authenticationSaveData, method: .post, encoding: body, headers: headers)
        APIManager.sharedInstance.request(with: requestHelper, isLoader: isLoader) { response in
            if response.error == nil {
                completion?(true, "Authentication Data Saved - \(uniqueId) - \(isSuccess)")
            } else {
                completion?(false, "\(String(describing: response.error?.localizedDescription))")
            }
        }
    }
}
