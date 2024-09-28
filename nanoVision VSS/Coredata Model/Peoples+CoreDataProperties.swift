//
//  Peoples+CoreDataProperties.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 28/09/24.
//
//

import Foundation
import CoreData


extension Peoples {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Peoples> {
        return NSFetchRequest<Peoples>(entityName: "Peoples")
    }

    @NSManaged public var peopleid: Int64
    @NSManaged public var firstname: String?
    @NSManaged public var middlename: String?
    @NSManaged public var lastname: String?
    @NSManaged public var email: String?
    @NSManaged public var phone: Int64
    @NSManaged public var additionaldetails: String?
    @NSManaged public var listid: [String]?
    @NSManaged public var isactive: Bool
    @NSManaged public var embeddedimage: [Float]?
    @NSManaged public var eventID: Int64
    @NSManaged public var locationid: Int64
    @NSManaged public var isdelete: Bool
    @NSManaged public var welcomemsg: String?
    @NSManaged public var qrcode: String?
    @NSManaged public var usertype: String?
    @NSManaged public var lastmodifieddate: String?
    @NSManaged public var uniqueId: String?

}

extension Peoples : Identifiable {

}
