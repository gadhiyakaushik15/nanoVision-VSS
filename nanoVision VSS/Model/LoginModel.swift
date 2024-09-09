//
//  LoginModel.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 04/04/24.
//

import Foundation

// MARK: - LoginModel
struct LoginModel: Codable {
    let status: String?
    let results: Results?
    let message: String?
}

// MARK: - Results
struct Results: Codable {
    let authorization: [Authorization]?
    let devicesDetails: [DevicesDetail]?

    enum CodingKeys: String, CodingKey {
        case authorization
        case devicesDetails = "devices_details"
    }
}

// MARK: - Authorization
struct Authorization: Codable {
    let accesstoken, refreshtoken: String?
}

// MARK: - DevicesDetail
struct DevicesDetail: Codable {
    let deviceStatus, deviceMessage: String?
    let device: [Device]?
    let isDefaultKioskAssigned: Bool?
    let deviceKioskMessage: String?
    let kioskDetails: [KioskDetail]?
    let deviceEventMessage: String?
    let isDefaultEventAssigned: Bool?
    let eventidDetails: [EventidDetail]?

    enum CodingKeys: String, CodingKey {
        case deviceStatus = "device_status"
        case deviceMessage = "device_message"
        case device
        case isDefaultKioskAssigned = "is_default_kiosk_assigned"
        case deviceKioskMessage = "device_kiosk_message"
        case kioskDetails = "kiosk_details"
        case deviceEventMessage = "device_event_message"
        case isDefaultEventAssigned = "is_default_event_assigned"
        case eventidDetails
    }
}

// MARK: - Device
struct Device: Codable {
    let accountid: Int?
    let accountname, address: String?
    let subscriptionid: Int?
    let orgID, apiKey, appLogo, lastmodifieddate: String?
    let createddate, deviceLimit: String?
    let deviceid: Int?
    let isactive: Bool?
    let kioskid: Int?
    let devicename, devicetype, devicemac, status: String?
    let isdeleted: Bool?
    let defaultevent: Int?
    let assignedrelay: String?
    let accesscontrolid: Int?
    let accesscontrolername: String?
    let mqttenabled: Bool?

    enum CodingKeys: String, CodingKey {
        case accountid, accountname, address, subscriptionid
        case orgID = "org_id"
        case apiKey = "api_key"
        case appLogo = "app_logo"
        case lastmodifieddate, createddate
        case deviceLimit = "device_limit"
        case deviceid, isactive, kioskid, devicename, devicetype, devicemac, status, isdeleted, defaultevent, assignedrelay, accesscontrolid
        case accesscontrolername = "accesscontroler_name"
        case mqttenabled = "mqtt_enabled"
    }
}

// MARK: - EventidDetail
struct EventidDetail: Codable {
    let eventid: Int?
    let eventname, eventdescription, eventstartdatetime, eventenddatetime: String?
    let accountid, locationid, kioskid: Int?
    let lastmodifieddate, createddate: String?
    let isdeleted, isdefault: Bool?
}

// MARK: - KioskDetail
struct KioskDetail: Codable {
    let kioskid, accountid: Int?
    let scanmessage, appLogo, displayname, scansuccess: String?
    let scanfailure, kioskname: String?
    let isdefault: Bool?
    let createddate, lastmodifieddate: String?
    let peoplespecificmsg, enablefutureeventscan, enableexpiredeventscan: Bool?
    let futureeventscanmsg, expiredeventscanmsg: String?

    enum CodingKeys: String, CodingKey {
        case kioskid, accountid, scanmessage
        case appLogo = "app_logo"
        case displayname, scansuccess, scanfailure, kioskname, isdefault, createddate, lastmodifieddate
        case peoplespecificmsg = "people_specific_msg"
        case enablefutureeventscan = "enable_future_event_scan"
        case enableexpiredeventscan = "enable_expired_event_scan"
        case futureeventscanmsg = "future_event_scan_msg"
        case expiredeventscanmsg = "expired_event_scan_msg"
    }
}
