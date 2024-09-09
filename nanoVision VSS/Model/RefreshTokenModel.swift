//
//  RefreshTokenModel.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 05/04/24.
//

import Foundation

// MARK: - RefreshTokenModel
struct RefreshTokenModel: Codable {
    let status: String?
    let results: Result?
    let message: String?
}

// MARK: - Result
struct Result: Codable {
    let accesstoken: String?
}
