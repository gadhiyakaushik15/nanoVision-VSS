//
//  GetVisitorModel.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 11/06/24.
//

import Foundation

// MARK: - GetVisitorModel
struct GetVisitorModel: Codable {
    let status: String?
    let result: [VisitorResult]?
    let message: String?
}

// MARK: - VisitorResult
struct VisitorResult: Codable {
    let firstname, lastname, email, phone: String?
    let visitorID: Int?
    let visitorImage: String?

    enum CodingKeys: String, CodingKey {
        case firstname, lastname, email, phone
        case visitorID = "visitor_id"
        case visitorImage = "visitor_image"
    }
}
