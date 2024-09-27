//
//  Constants.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 12/04/24.
//

import Foundation

struct Constants {
    static let AutoSyncTime = 2.0 // Auto Sync time in Seconds.
    static let LivenessThreshold: Float = 0.5 // 0 to 1
    static let ZipFileName = "people_data.zip"
    static let PeopleDataFolderName = "people_data"
    static let CsvFileName = "data.csv"
    static let DeviceType = "iOS"
    static let MatchScoreThreshold: Int = 700 // 0 to 1000
    static let TermsAndConditionsUrl = "\(baseURL)/t&c"
    static let PrivacyPolicyUrl = "\(baseURL)/privacy"
    static let NextScanDelayDefault: Float = 2.0
    static let NextScanDelayMinimum: Float = 1.0
    static let NextScanDelayMaximum: Float = 10.0
    static let AppStoreUrl = "https://apps.apple.com/app/nanovision-face-ai/id6502285726"
    static let ViableSoftApiKey = "fe6d935c-2f7d-4f1c-8850-1a5290b3f81e"
    static let DefaultLastSyncTimeStamp = "1990-02-05 17:02:33.615"
    static let LogsSyncTime = 10 // Auto Logs Sync time in Minutes.
}

struct MQTT {
    static let Host = "6254b73a36634b358f6f5d77cf153cf6.s1.eu.hivemq.cloud"
    static let Identifier = UUID().uuidString
    static let Port: UInt16 = 8883
    static let Username = "ashok"
    static let Password = "Ashok@123456"
    static let SubscriberTopic = "stat/%@/POWER" + "%d"
    static let PublisherTopic = "cmnd/%@/power" + "%d"
    static let OnCommand = "ON"
    static let OffCommand = "OFF"
}

struct APIStatus {
    static let Success = "success"
    static let Failed = "failed"
    static let PartialSuccess = "partial_success"
}

struct DeviceStatus {
    static let Approved = "approved"
    static let Pending = "pending"
    static let Rejected = "rejected"
}

struct UserType {
    static let Visitor = "visitor"
    static let Regular = "regular"
}

struct HeaderValue {
    static let ContentType  = "Content-Type"
    static let ContentValue = "application/json"
    static let ContentValue2 = "application/json; charset=UTF-8"
    static let ContentValue3 = "multipart/form-data"
    static let ContentValue4 = "text/plain"
    static let Authorization  = "Authorization"
    static let RefreshToken = "refreshtoken"
    static let ApiKey  = "apiKey"
}

struct Validation {
    static let SomethingWrong = "Something went wrong, please try again"
    static let OrganizationIdEnter = "Please enter organization id"
    static let APIKeyEnter = "Please enter API key"
    static let FirstNameEnter = "Please enter first name"
    static let LastNameEnter = "Please enter last name"
    static let PhoneNumberEnter = "Please enter 10 digit phone number"
    static let EmailIdValid = "Please enter valid email id"
    static let WhomToMeetSelect = "Please select whom to meet"
    static let PurposeOfVisitSelect = "Please select purpose of visit"
    static let DaySelect = "Please select day"
    static let LocationSelect = "Please select location"
}

struct Message {
    static let InvalidToken = "Invalid token"
    static let PleaseWaitSyncInProcess = "Please wait, Sync in Process"
    static let PleaseCheckYourInternetConnection = "Please check your internet connection"
    static let Confirm = "Confirm"
    static let AreYouSureYouWantToLogout = "Are you sure you want to logout?"
    static let Cancel = "Cancel"
    static let DeviceApproval = "Device Approval"
    static let DeviceApprovedMessage = "Device successfully approved"
    static let DeviceRejectedMessage = "Your device has been rejected"
    static let DevicePendingMessage = "Device approval is pending"
    static let KioskAssignment = "Kiosk Assignment"
    static let KioskAssigned = "Kiosk successfully assigned"
    static let KioskAssignmentPending = "Kiosk assignment is pending"
    static let EventAssignment = "Event Assignment"
    static let EventAssigned = "Event successfully assigned"
    static let EventAssignmentPending = "Event assignment is pending"
    static let RelayAssignment = "Relay Assignment"
    static let RelayAssigned = "Relay successfully assigned"
    static let RelayAssignmentPending = "Relay assignment is pending"
    static let AuthorisedPerson = "Authorised Person"
    static let UnauthorisedPerson = "Unauthorised Person"
    static let ManualScanMode = "Manual Scan Mode"
    static let ManualScanModeTips = "Toggle between manual and automatic scan modes. When in manual mode, a 'Scan' button will appear for capturing and authenticating faces."
    static let LivenessCheck = "Liveness Check"
    static let LivenessCheckTips = "Toggle to enable or disable liveness check. When enabled, the app will verify if the face being scanned is a real selfie or a spoof."
    static let SelectedEvent = "Selected Event"
    static let Expired = "Expired"
    static let ScanLogs = "Scan Logs"
    static let SyncStats = "Sync Stats"
    static let TotalNumberOfPeople = "Total Number of People"
    static let LastSyncTime = "Last Sync Time"
    static let TotalNumberOfLogs = "Total Number of Logs"
    static let SyncedWithServer = "Synced With Server"
    static let PeopleSyncDetails = "People Sync Details"
    static let LogSyncDetails = "Log Sync Details"
    static let People = "People"
    static let Log = "Log"
    static let Logs = "Logs"
    static let ScanSettings = "Scan Settings"
    static let EventDetails = "Event Details"
    static let CameraPermissionMessage = "App requires access to the camera for scan your face, we request you to give permission from settings"
    static let FutureEventMessage = "The event hasn't started yet."
    static let ExpiredEventMessage = "The event was over."
    static let SuccessfullyLoggedIn = "You have successfully logged in."
    static let SearchUserName = "Search user name"
    static let NoLogsFound = "No logs found"
    static let TermsOfUse = "Terms of Use"
    static let PrivacyPolicy = "Privacy Policy"
    static let Welcome = "Welcome"
    static let AgreeTo = "By continuing, you agree to our Terms of Use and acknowledge that you have read our Privacy Policy"
    static let LogsAndStats = "Logs and Stats"
    static let DataAndPrivacy = "Data and Privacy"
    static let UnlockControlCenter = "Unlock Control Center"
    static let UpdateAvailable = "Update available!"
    static let UpdateMessage = "The %@ app version %@ is available on the AppStore"
    static let Update = "Update"
    static let Sound = "Sound"
    static let ScanSoundTips = "Turn on this option to play audio feedback when face scanning is successful or fails."
    static let NextScanDelay = "Next Scan Delay"
    static let NextScanDelayTips = "Set the delay before the scan screen automatically reopens. Enable to specify the delay time in seconds."
    static let Second = "Second"
    static let Seconds = "Seconds"
    static let TapToScanOnSuccess = "Tap to Scan on Success"
    static let TapToScanOnSuccessTips = "Enable tap action for the next user to proceed after a successful face scan."
    static let TapToScanOnFailure = "Tap to Scan on Failure"
    static let TapToScanOnFailureTips = "Enable tap action for rescanning after a failed face scan."
    static let purposeOfVisit = "Purpose of Visit"
    static let SearchWhomToMeet = "Search Whom to Meet"
    static let NoDataFound = "No Data found"
    static let RestrictUserForCreatingVisitorPassMessage = "You are a registered user. Please scan your face for authentication."
    static let Ok = "Ok"
    static let Error = "Error"
    static let VisitorVerificationMessage = "This phone number is already associated with another visitor in our system. Please use a different phone number."
    static let VisitorRegistrationSuccessfully = "Your visitor pass is generated successfully!\n\nPress 'Start Scanning' button to scan your face for authentication."
    static let VisitorVerificationEmailMessage = "This email id is already associated with another visitor in our system. Please use a different email id."

}
