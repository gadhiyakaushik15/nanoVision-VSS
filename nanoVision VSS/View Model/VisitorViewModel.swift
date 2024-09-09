//
//  VisitorViewModel.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 06/06/24.
//

import Foundation
import Alamofire

class VisitorViewModel: NSObject {
    
    func createVisitor(firstName: String, lastName: String, emailId: String, phoneNumber: String, whomToMeetId: Int, purposeOfVisit: String, embeddings: String, isLoader: Bool, completion:@escaping(VisitorEntryModel?) -> Void) {
        let headers: HTTPHeaders = [HeaderValue.Authorization: "Bearer \(UserDefaultsServices.shared.getAccessToken())"]
        let param = [ "firstname": firstName,
                      "lastname": lastName,
                      "email": emailId,
                      "phone": phoneNumber,
                      "whom_to_meet": whomToMeetId,
                      "purpose_of_visit": purposeOfVisit,
                      "visitor_image": embeddings
        ] as! [String: Any]
        
        //        debugPrint(API.peopleEntry)
        //        debugPrint(headers)
        //        debugPrint(param)
        
        let requestHelper = RequestHelper(url: API.visitorEntry, method: .post, parameters: param, encoding: JSONEncoding.default, headers: headers)
        APIManager.sharedInstance.request(with: requestHelper, isLoader: isLoader) { response in
            if response.error == nil {
                if let responseDa = response.responseData {
                    let json = try? JSONDecoder().decode(VisitorEntryModel.self, from: responseDa)
                    completion(json)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    func getVisitor(phoneNumber: String, isLoader: Bool, completion:@escaping(GetVisitorModel?) -> Void) {
        let headers: HTTPHeaders = [HeaderValue.Authorization: "Bearer \(UserDefaultsServices.shared.getAccessToken())"]
        let param = [ "phone": phoneNumber ] as! [String: Any]
        
        //        debugPrint(API.getVisitor)
        //        debugPrint(headers)
        //        debugPrint(param)
        
        let requestHelper = RequestHelper(url: API.getVisitor, method: .post, parameters: param, encoding: JSONEncoding.default, headers: headers)
        APIManager.sharedInstance.request(with: requestHelper, isLoader: isLoader) { response in
            if response.error == nil {
                if let responseDa = response.responseData {
                    let json = try? JSONDecoder().decode(GetVisitorModel.self, from: responseDa)
                    completion(json)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    
    func getVisitor(email: String, isLoader: Bool, completion:@escaping(GetVisitorModel?) -> Void) {
        let headers: HTTPHeaders = [HeaderValue.Authorization: "Bearer \(UserDefaultsServices.shared.getAccessToken())"]
        let param = [ "email": email ] as! [String: Any]
        
        //        debugPrint(API.getVisitor)
        //        debugPrint(headers)
        //        debugPrint(param)
        
        let requestHelper = RequestHelper(url: API.getVisitor, method: .post, parameters: param, encoding: JSONEncoding.default, headers: headers)
        APIManager.sharedInstance.request(with: requestHelper, isLoader: isLoader) { response in
            if response.error == nil {
                if let responseDa = response.responseData {
                    let json = try? JSONDecoder().decode(GetVisitorModel.self, from: responseDa)
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
