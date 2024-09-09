//
//  APIManager.swift
//  Ziipcourier
//
//  Created by Ankur Kathiriya on 26/04/22.
//

import UIKit
import Alamofire

final class APIManager {
    
    static let sharedInstance: APIManager = APIManager()
    
    func request(with requestHelper: RequestHelper?, isLoader:Bool, completion : ((_ response : ResponseHelper) -> Void)?) {
        
        // Create request
        guard let requestData = requestHelper, let url = try? requestData.url.asURL() else {
            let responseData = ResponseHelper(responseData: nil, error: nil)
            completion?(responseData)
            return
        }
        
        // API call
        if APIManager.isConnectedToInternet() {
            if isLoader {
                Utilities.shared.showSVProgressHUD()
            }
            AF.request(url, method: requestData.method, parameters: requestData.parameters, encoding: requestData.encoding, headers: requestData.headers)
                .validate(statusCode: 200..<500)
                .responseJSON {
                    response in
                    if isLoader {
                        Utilities.shared.dismissSVProgressHUD()
                    }
                    switch response.result {
                    case .success(let value):
                        if let json = value as? NSDictionary {
//                           debugPrint(json)
                            if let msg = json.value(forKey: "message")as? String {
                                if msg == Message.InvalidToken {
                                    LoginViewModel().refreshToken { data in
                                        if let data = data, let result = data.results, let accesstoken = result.accesstoken {
                                            UserDefaultsServices.shared.saveAccessToken(token: accesstoken)
                                            var requestHelperNew = requestHelper
                                            let headers: HTTPHeaders = [HeaderValue.Authorization: "Bearer \(UserDefaultsServices.shared.getAccessToken())"]
                                            requestHelperNew?.headers = headers
                                            self.request(with: requestHelperNew, isLoader: isLoader) { response in
                                                completion?(response)
                                            }
                                        } else {
                                            let responseData = ResponseHelper(responseData: nil, error: nil)
                                            completion?(responseData)
                                        }
                                    }
                                } else {
                                    let responseData = ResponseHelper(responseData: response.data, error: response.error)
                                    completion?(responseData)
                                }
                            } else {
                                let responseData = ResponseHelper(responseData: response.data, error: response.error)
                                completion?(responseData)
                            }

                        } else if let array = value as? NSArray, let json = array.firstObject {
//                            debugPrint(json)
                            let responseData = ResponseHelper(responseData: response.data, error: response.error)
                            completion?(responseData)
                        }
                        break
                    case .failure(let error):
                        debugPrint(response.result)
                        let responseData = ResponseHelper(responseData: response.data, error: error)
                        completion?(responseData)
                        break
                    }
                }
        } else {
            let error = NSError(domain: "", code: URLError.Code.notConnectedToInternet.rawValue, userInfo: [ NSLocalizedDescriptionKey: Message.PleaseCheckYourInternetConnection])
            let responseData = ResponseHelper(responseData: nil, error: error)
            completion?(responseData)
        }
    }
        
    // Internet rechability checking
    class func isConnectedToInternet() -> Bool {
        return NetworkReachabilityManager()?.isReachable ?? false
    }
}

// Request helper struct
struct RequestHelper {
    let url: URLConvertible
    var method: HTTPMethod = .get
    var parameters: Parameters = [:]
    var encoding: ParameterEncoding = URLEncoding.default
    var headers: HTTPHeaders? = nil
    var uploadData: [Data] = []
    var fileNames: [String] = []
    var fileExtension: String = ""
    var fileMimeType: String = ""
    
    init(url: URLConvertible, method: HTTPMethod) {
        self.url = url
        self.method = method
    }
    
    init(url: URLConvertible, method: HTTPMethod, parameters: Parameters) {
        self.url = url
        self.method = method
        self.parameters = parameters
    }
    
    init(url: URLConvertible, method: HTTPMethod, headers: HTTPHeaders?) {
        self.url = url
        self.method = method
        self.headers = headers
    }
    
    init(url: URLConvertible, method: HTTPMethod, parameters: Parameters, headers: HTTPHeaders?) {
        self.url = url
        self.method = method
        self.parameters = parameters
        self.headers = headers
    }
    
    init(url: URLConvertible, method: HTTPMethod, parameters: Parameters, headers: HTTPHeaders?, uploadData: [Data], fileNames: [String], fileExtension: String, fileMimeType: String) {
        self.url = url
        self.method = method
        self.parameters = parameters
        self.headers = headers
        self.uploadData = uploadData
        self.fileNames = fileNames
        self.fileExtension = fileExtension
        self.fileMimeType = fileMimeType
    }
    
    init(url: URLConvertible, method: HTTPMethod, parameters: Parameters, encoding: ParameterEncoding, headers: HTTPHeaders?) {
        self.url = url
        self.method = method
        self.parameters = parameters
        self.encoding = encoding
        self.headers = headers
    }
    
    init(url: URLConvertible, method: HTTPMethod, encoding: ParameterEncoding, headers: HTTPHeaders) {
        self.url = url
        self.method = method
        self.encoding = encoding
        self.headers = headers
    }
}

// Response Helper struct
struct ResponseHelper {
    let responseData : Data?
    let error : Error?
    init(responseData : Data?, error : Error?) {
        self.responseData = responseData
        self.error = error
    }
}

public struct MyCustomEncoding : ParameterEncoding {
    private let data: Data
    init(data: Data) {
        self.data = data
    }
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        
        var urlRequest = try urlRequest.asURLRequest()
        do{
            urlRequest.httpBody = data
        }
        
        return urlRequest
    }
}
