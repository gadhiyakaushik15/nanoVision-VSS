//
//  CreateLogsModel.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 17/04/24.
//

import Foundation

// MARK: - CreateLogsModel
struct CreateLogsModel: Codable {
    let status: String?
    let result: CreateLogsResult?
    let message: String?
}

// MARK: - Result
struct CreateLogsResult: Codable {
    let insertedIDS, failedIDS: [Int]?

    enum CodingKeys: String, CodingKey {
        case insertedIDS = "insertedIds"
        case failedIDS = "failedIds"
    }
}
