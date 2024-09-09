//
//  LocationModel.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 09/09/24.
//

import Foundation

// MARK: - LocationModel
struct LocationModel: Codable {
    let id: Int?
    let gate, entryExit: String?
}
