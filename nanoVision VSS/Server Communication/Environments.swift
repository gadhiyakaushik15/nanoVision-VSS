//
//  Environments.swift
//  Paravision
//
//  Created by Kaushik Gadhiya on 08/02/24.
//

import Foundation

//Environment Type
enum EnvironmentType : Int {
    case UAT = 0
    case PROD = 1
}

//Current Environment
let currentEnvironmentType = EnvironmentType.PROD

//Environment Declaration
struct Environments {
    
    //Declaration of API Base URL Based on Current Environment
    static var BaseURL : String {
        switch currentEnvironmentType {
        case .UAT:
            return "https://middleware-3141a3337450.herokuapp.com"
        case .PROD:
            return "https://middleware-3141a3337450.herokuapp.com"
        }
    }
    
    //Declaration of API Viable Soft Base URL Based on Current Environment
    static var ViableSoftBaseURL : String {
        switch currentEnvironmentType {
        case .UAT:
            return "https://www.viablesoft.org.in"
        case .PROD:
            return "https://www.viablesoft.org.in"
        }
    }
}

//Base URL
let baseURL = Environments.BaseURL
let viableSoftBaseURL = Environments.ViableSoftBaseURL
