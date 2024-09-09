//
//  Singleton.swift
//  Paravision
//
//  Created by Ankur Kathiriya on 10/01/24.
//

import Foundation

class OfflinePeoples {
    static let shared = OfflinePeoples()
    private init(){}
    var peoples: [PeoplesModel] = []
}

class OfflineDevicesDetails {
    static let shared = OfflineDevicesDetails()
    private init(){}
    var devicesDetails: DevicesDetail?
}
