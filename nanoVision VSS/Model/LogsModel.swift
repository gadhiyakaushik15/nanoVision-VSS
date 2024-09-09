//
//  LogsModel.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 16/04/24.
//

import Foundation

// MARK: - LogsModel
struct LogsModel: Codable {
    let status: String?
    let results: [LogsResult]?
    let message: String?
}

// MARK: - Result
struct LogsResult: Codable {
    let base64String: Data?
    let message, createddate: String?
    let devicetype: String?
    let peopleid, confidencescore: Int?
    let eventid: Int?
    let apiresponse: String?
    let logid, deviceid, applogid: Int?
    let listid: String?
    var iscreated: Bool = false
    var eventname = ""
    var peoplename = ""
    var scantype: Int?
    var usertype: String?

    enum CodingKeys: String, CodingKey {
        case base64String = "base64string"
        case confidencescore, message, createddate, devicetype, peopleid, eventid, apiresponse, logid, deviceid, iscreated, eventname, peoplename, scantype
        case applogid = "app_log_id"
        case listid = "list_id"
        case usertype = "user_type"
    }
}
