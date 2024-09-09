//
//  Logs+CoreDataClass.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 17/04/24.
//
//

import Foundation
import CoreData

@objc(Logs)
public class Logs: NSManagedObject, Codable {
    
    enum CodingKeys: String, CodingKey {
        case base64String = "base64string"
        case confidencescore, message, createddate, devicetype, peopleid, eventid, apiresponse, logid, deviceid, iscreated, eventname, peoplename, scantype
        case applogid = "app_log_id"
        case listid = "list_id"
        case usertype = "user_type"
    }
    
    // MARK: - Decodable
    required convenience public init(from decoder: Decoder) throws {
        
        //Fetch context for codable
        guard let codableContext = CodingUserInfoKey.init(rawValue: "context"),
            let manageObjContext = decoder.userInfo[codableContext] as? NSManagedObjectContext,
            let manageObjList = NSEntityDescription.entity(forEntityName: "Logs", in: manageObjContext) else {
            fatalError("failed")
        }
        
        self.init(entity: manageObjList, insertInto: manageObjContext)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.base64String = try container.decodeIfPresent(Data.self, forKey: .base64String) ?? nil
        self.confidencescore = try container.decodeIfPresent(Int64.self, forKey: .confidencescore) ?? 0
        self.message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        self.createddate = try container.decodeIfPresent(String.self, forKey: .createddate) ?? ""
        self.devicetype = try container.decodeIfPresent(String.self, forKey: .devicetype) ?? ""
        self.peopleid = try container.decodeIfPresent(Int64.self, forKey: .peopleid) ?? 0
        self.eventid = try container.decodeIfPresent(Int64.self, forKey: .eventid) ?? 0
        self.apiresponse = try container.decodeIfPresent(String.self, forKey: .apiresponse) ?? ""
        self.logid = try container.decodeIfPresent(Int64.self, forKey: .logid) ?? 0
        self.deviceid = try container.decodeIfPresent(Int64.self, forKey: .deviceid) ?? 0
        self.applogid = try container.decodeIfPresent(Int64.self, forKey: .applogid) ?? 0
        self.iscreated = try container.decodeIfPresent(Bool.self, forKey: .iscreated) ?? false
        self.listid = try container.decodeIfPresent(String.self, forKey: .listid) ?? ""
        self.eventname = try container.decodeIfPresent(String.self, forKey: .eventname) ?? ""
        self.peoplename = try container.decodeIfPresent(String.self, forKey: .peoplename) ?? ""
        self.scantype = try container.decodeIfPresent(Int64.self, forKey: .scantype) ?? 0
        self.usertype = try container.decodeIfPresent(String.self, forKey: .usertype) ?? ""
    }
    
    // MARK: - encode
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.base64String, forKey: .base64String)
        try container.encode(self.confidencescore, forKey: .confidencescore)
        try container.encode(self.message, forKey: .message)
        try container.encode(self.createddate, forKey: .createddate)
        try container.encode(self.devicetype, forKey: .devicetype)
        try container.encode(self.peopleid, forKey: .peopleid)
        try container.encode(self.eventid, forKey: .eventid)
        try container.encode(self.apiresponse, forKey: .apiresponse)
        try container.encode(self.logid, forKey: .logid)
        try container.encode(self.deviceid, forKey: .deviceid)
        try container.encode(self.applogid, forKey: .applogid)
        try container.encode(self.iscreated, forKey: .iscreated)
        try container.encode(self.listid, forKey: .listid)
        try container.encode(self.eventname, forKey: .eventname)
        try container.encode(self.peoplename, forKey: .peoplename)
        try container.encode(self.scantype, forKey: .scantype)
        try container.encode(self.usertype, forKey: .usertype)
    }
}
