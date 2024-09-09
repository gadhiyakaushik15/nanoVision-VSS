//
//  LoginViewModel.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 04/04/24.
//

import Foundation
import Alamofire

class LoginViewModel: NSObject {
    
    // MARK: - Login Api integration
    func loginApi(orgId: String, apiKey: String, type: String, deviceMac: String, isLoader: Bool, completion:@escaping(LoginModel?, Error?) -> Void) {
        
        let headers: HTTPHeaders = [HeaderValue.ContentType:HeaderValue.ContentValue2]
        
        let param = ["org_id": orgId,
                     "api_key": apiKey,
                     "type": type,
                     "device_mac": deviceMac
        ] as! [String: Any]
        
//        debugPrint(API.login)
//        debugPrint(headers)
//        debugPrint(param)
        
        let requestHelper = RequestHelper(url: API.login, method: .post, parameters: param, encoding: JSONEncoding.default, headers: headers)
        APIManager.sharedInstance.request(with: requestHelper, isLoader: isLoader) { response in
            if response.error == nil {
                if let responseDa = response.responseData {
                    let json = try? JSONDecoder().decode(LoginModel.self, from: responseDa)
                    completion(json, nil)
                } else {
                    completion(nil, nil)
                }
            } else {
                completion(nil, response.error)
            }
        }
    }
    
    func refreshToken(completion:@escaping(RefreshTokenModel?) -> Void) {
        let headers: HTTPHeaders = [HeaderValue.RefreshToken:"\(UserDefaultsServices.shared.getRefreshToken())"]
        
//        debugPrint(API.refreshToken)
//        debugPrint(headers)
        
        let requestHelper = RequestHelper(url: API.refreshToken, method: .get, headers: headers)
        APIManager.sharedInstance.request(with: requestHelper, isLoader: false) { response in
            if response.error == nil {
                if let responseDa = response.responseData {
                    let json = try? JSONDecoder().decode(RefreshTokenModel.self, from: responseDa)
                    completion(json)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    func getDeviceStatus(deviceMac: String, isLoader: Bool, completion:@escaping(DeviceStatusModel?) -> Void) {
        let headers: HTTPHeaders = [HeaderValue.Authorization: "Bearer \(UserDefaultsServices.shared.getAccessToken())"]
        let param = ["device_mac": deviceMac] as! [String: Any]
        
//        debugPrint(API.getDeviceStatus)
//        debugPrint(headers)
//        debugPrint(param)
        
        let requestHelper = RequestHelper(url: API.getDeviceStatus, method: .post, parameters: param, encoding: JSONEncoding.default, headers: headers)
        APIManager.sharedInstance.request(with: requestHelper, isLoader: isLoader) { response in
            if response.error == nil {
                if let responseDa = response.responseData {
                    let json = try? JSONDecoder().decode(DeviceStatusModel.self, from: responseDa)
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
