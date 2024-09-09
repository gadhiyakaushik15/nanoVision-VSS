//
//  PeopleDataModel.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 08/04/24.
//

import Foundation

// MARK: - PeopleDataModel
struct PeopleDataModel: Codable {
    let status: String?
    let result: PeopleDataResult?
    let message: String?
}

// MARK: - Result
struct PeopleDataResult: Codable {
    let peopleInformation: String?

    enum CodingKeys: String, CodingKey {
        case peopleInformation = "people_information"
    }
}

