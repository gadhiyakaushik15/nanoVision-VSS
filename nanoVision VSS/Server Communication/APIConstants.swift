//
//  APIConstants.swift
//  Paravision
//
//  Created by Ankur Kathiriya on 02/01/24.
//

import UIKit
import Foundation

/*==============================================
* Struct Purpose: -> Call this struct for getting API endpoints.
 
* How to Use: -> API.login
* =============================================*/
struct API {
    
    static let login = baseURL + "/api/v1/auth/login"
    static let refreshToken = baseURL + "/api/v1/auth/refresh_token"
    static let getDeviceStatus = baseURL + "/api/v1/account/getdevicestatus"
    static let peopleData = baseURL + "/api/v3/account/people_data"
    static let getLogs = baseURL + "/api/v1/account/get_logs"
    static let createLogs = baseURL + "/api/v1/account/create_logs"
    static let visitorEntry = baseURL + "/api/v1/account/visitor_entry"
    static let getVisitor = baseURL + "/api/v1/account/get_visitor"
    
    static let authenticationSaveData = viableSoftBaseURL + "/IEIA2025mayDelFaceVD/api/v1/face/AuthenticationsaveData"
    static let day = viableSoftBaseURL + "/IEIA2025mayDelFaceVD/api/v1/face/day"
    static let locationTable = viableSoftBaseURL + "/IEIA2025mayDelFaceVD/api/v1/face/locationtable"

}
//=============end Struct========================

