//
//  Logs+CoreDataProperties.swift
//  
//
//  Created by Kaushik Gadhiya on 07/06/24.
//
//

import Foundation
import CoreData


extension Logs {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Logs> {
        return NSFetchRequest<Logs>(entityName: "Logs")
    }

    @NSManaged public var apiresponse: String?
    @NSManaged public var applogid: Int64
    @NSManaged public var base64String: Data?
    @NSManaged public var confidencescore: Int64
    @NSManaged public var createddate: String?
    @NSManaged public var deviceid: Int64
    @NSManaged public var devicetype: String?
    @NSManaged public var eventid: Int64
    @NSManaged public var eventname: String?
    @NSManaged public var iscreated: Bool
    @NSManaged public var listid: String?
    @NSManaged public var logid: Int64
    @NSManaged public var message: String?
    @NSManaged public var peopleid: Int64
    @NSManaged public var peoplename: String?
    @NSManaged public var scantype: Int64
    @NSManaged public var usertype: String?

}
