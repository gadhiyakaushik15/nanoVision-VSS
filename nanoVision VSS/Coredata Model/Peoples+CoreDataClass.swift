//
//  Peoples+CoreDataClass.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 28/09/24.
//
//

import Foundation
import CoreData

@objc(Peoples)
public class Peoples: NSManagedObject, Codable {
    var matchScore: Int?
    
    enum CodingKeys: String, CodingKey {
        case peopleid, firstname, middlename, lastname, email, phone, additionaldetails, listid, isactive, embeddedimage, lastmodifieddate
        case eventID = "event_id"
        case locationid, isdelete, welcomemsg
        case qrcode = "qr_code"
        case usertype = "user_type"
        case uniqueId = "unique_id"
    }
    
    // MARK: - Decodable
    required convenience public init(from decoder: Decoder) throws {
        
        //Fetch context for codable
        guard let codableContext = CodingUserInfoKey.init(rawValue: "context"),
            let manageObjContext = decoder.userInfo[codableContext] as? NSManagedObjectContext,
            let manageObjList = NSEntityDescription.entity(forEntityName: "Peoples", in: manageObjContext) else {
            fatalError("failed")
        }
        
        self.init(entity: manageObjList, insertInto: manageObjContext)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.peopleid = try container.decodeIfPresent(Int64.self, forKey: .peopleid) ?? 0
        self.firstname = try container.decodeIfPresent(String.self, forKey: .firstname) ?? nil
        self.middlename = try container.decodeIfPresent(String.self, forKey: .middlename) ?? nil
        self.lastname = try container.decodeIfPresent(String.self, forKey: .lastname) ?? nil
        self.email = try container.decodeIfPresent(String.self, forKey: .email) ?? nil
        self.phone = try container.decodeIfPresent(Int64.self, forKey: .phone) ?? 0
        self.additionaldetails = try container.decodeIfPresent(String.self, forKey: .additionaldetails) ?? nil
        self.listid = try container.decodeIfPresent([String].self, forKey: .listid) ?? nil
        self.isactive = try container.decodeIfPresent(Bool.self, forKey: .isactive) ?? false
        self.embeddedimage = try container.decodeIfPresent([Float].self, forKey: .embeddedimage) ?? nil
        self.lastmodifieddate = try container.decodeIfPresent(String.self, forKey: .lastmodifieddate) ?? nil
        self.eventID = try container.decodeIfPresent(Int64.self, forKey: .eventID) ?? 0
        self.locationid = try container.decodeIfPresent(Int64.self, forKey: .locationid) ?? 0
        self.isdelete = try container.decodeIfPresent(Bool.self, forKey: .isdelete) ?? false
        self.welcomemsg = try container.decodeIfPresent(String.self, forKey: .welcomemsg) ?? nil
        self.qrcode = try container.decodeIfPresent(String.self, forKey: .qrcode) ?? nil
        self.usertype = try container.decodeIfPresent(String.self, forKey: .usertype) ?? nil
        self.uniqueId = try container.decodeIfPresent(String.self, forKey: .uniqueId) ?? nil
    }
    
    // MARK: - encode
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.peopleid, forKey: .peopleid)
        try container.encode(self.firstname, forKey: .firstname)
        try container.encode(self.middlename, forKey: .middlename)
        try container.encode(self.lastname, forKey: .lastname)
        try container.encode(self.email, forKey: .email)
        try container.encode(self.phone, forKey: .phone)
        try container.encode(self.additionaldetails, forKey: .additionaldetails)
        try container.encode(self.listid, forKey: .listid)
        try container.encode(self.isactive, forKey: .isactive)
        try container.encode(self.embeddedimage, forKey: .embeddedimage)
        try container.encode(self.lastmodifieddate, forKey: .lastmodifieddate)
        try container.encode(self.eventID, forKey: .eventID)
        try container.encode(self.locationid, forKey: .locationid)
        try container.encode(self.isdelete, forKey: .isdelete)
        try container.encode(self.welcomemsg, forKey: .welcomemsg)
        try container.encode(self.qrcode, forKey: .qrcode)
        try container.encode(self.usertype, forKey: .usertype)
        try container.encode(self.uniqueId, forKey: .uniqueId)
    }
}
