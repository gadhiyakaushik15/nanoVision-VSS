//
//  DeviceStatusModel.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 05/04/24.
//

import Foundation

// MARK: - DeviceStatusModel
struct DeviceStatusModel: Codable {
    let status: String?
    let results: ResultsData?
    let message: String?
}

// MARK: - Results
struct ResultsData: Codable {
    let devicesDetails: [DevicesDetail]?

    enum CodingKeys: String, CodingKey {
        case devicesDetails = "devices_details"
    }
}
