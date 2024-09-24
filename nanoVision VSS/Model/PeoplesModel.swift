//
//  PeoplesModel.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 09/04/24.
//

import Foundation

// MARK: - PeoplesModel
struct PeoplesModel: Codable {
    let peopleid: Int?
    let firstname, middlename, lastname, email: String?
    let phone: Int?
    let additionaldetails: String?
    let listid: [String]?
    let isactive: Bool?
    let embeddedimage: [Float]?
    let eventID: Int?
    let locationid: Int?
    let isdelete: Bool?
    let welcomemsg: String?
    var matchScore: Int?
    var qrcode: String?
    var usertype: String?
    var lastmodifieddate: String?
    var uniqueId: String?

    enum CodingKeys: String, CodingKey {
        case peopleid, firstname, middlename, lastname, email, phone, additionaldetails, listid, isactive, embeddedimage, lastmodifieddate
        case eventID = "event_id"
        case locationid, isdelete, welcomemsg
        case qrcode = "qr_code"
        case usertype = "user_type"
        case uniqueId = "unique_id"
    }
}
