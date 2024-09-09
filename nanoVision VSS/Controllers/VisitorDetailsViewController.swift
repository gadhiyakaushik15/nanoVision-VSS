//
//  VisitorDetailsViewController.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 30/05/24.
//

import UIKit

class VisitorDetailsViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var selfieContainerView: UIView!
    @IBOutlet weak var selfieImageView: UIImageView!
    @IBOutlet weak var firstNameView: UIView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameView: UIView!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var phoneNumberView: UIView!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var emailIdView: UIView!
    @IBOutlet weak var emailIdTextField: UITextField!
    @IBOutlet weak var whomToMeetTextField: UITextField!
    @IBOutlet weak var whomToMeetDropDownTextField: DropDown!
    @IBOutlet weak var purposeOfVisitDropDownTextField: DropDown!
    @IBOutlet weak var submitButton: UIButton!
    
    var selfieImage = UIImage()
    var embeddings = ""
    var visitor: VisitorResult?
    var whomToMeetData: ListModel?
    var purposeOfVisitData: ListModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configUI()
        self.setDelegate()
        self.dataBind()
        self.setWhomToMeetDropDown()
        self.setPurposeOfVisitDropDown()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setLogo()
        self.setWhomToMeetData()
        LocalDataService.shared.syncCompleted = {
            DispatchQueue.main.async() {
                Utilities.shared.dismissSVProgressHUD()
                self.setLogo()
                self.setWhomToMeetData()
            }
            if Utilities.shared.isMQTTEnabled() {
                MQTTManager.shared().checkRelayChange()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        self.selfieContainerView.cornerRadiusV = self.selfieContainerView.frame.height / 2
        self.submitButton.cornerRadiusV = self.submitButton.frame.height / 2
    }
    
    // MARK: Config UI
    func configUI() {
        Utilities.shared.addSideRadiusWithOpacity(view: self.lineView, radius: 0, shadowRadius: 4, opacity: 1, shadowOffset: CGSize(width: 0 , height: 4), shadowColor: UIColor.black.withAlphaComponent(0.25), corners: [])
        
        if Utilities.shared.isPadDevice() {
            self.selfieContainerView.borderWidthV = 1.0
            let backConfig = UIImage.SymbolConfiguration(
                pointSize: 26, weight: .heavy, scale: .large)
            let backImage = UIImage(systemName: "arrow.backward", withConfiguration: backConfig)
            self.backButton.setImage(backImage, for: .normal)
        } else {
            self.selfieContainerView.borderWidthV = 0.65
            let backConfig = UIImage.SymbolConfiguration(
                pointSize: 18, weight: .heavy, scale: .medium)
            let backImage = UIImage(systemName: "arrow.backward", withConfiguration: backConfig)
            self.backButton.setImage(backImage, for: .normal)
        }
    }
    
    func setDelegate() {
        self.firstNameTextField.delegate = self
        self.lastNameTextField.delegate = self
        self.phoneNumberTextField.delegate = self
        self.emailIdTextField.delegate = self
    }
    
    func setWhomToMeetDropDown() {
        if Utilities.shared.isPadDevice() {
            self.whomToMeetDropDownTextField.arrowSize = 22.0
            self.whomToMeetDropDownTextField.rowHeight = 50.0
            self.whomToMeetDropDownTextField.listHeight = self.whomToMeetDropDownTextField.rowHeight * 4
            self.whomToMeetDropDownTextField.paddingLeft = 15
            self.whomToMeetDropDownTextField.paddingRight = 50
        } else {
            self.whomToMeetDropDownTextField.arrowSize = 15.0
            self.whomToMeetDropDownTextField.rowHeight = 40.0
            self.whomToMeetDropDownTextField.listHeight = self.whomToMeetDropDownTextField.rowHeight * 4
            self.whomToMeetDropDownTextField.paddingLeft = 12
            self.whomToMeetDropDownTextField.paddingRight = 40
        }
        self.whomToMeetDropDownTextField.didSelectCompletion = { list in
            self.whomToMeetData = list
        }
    }
    
    func setWhomToMeetData() {
        var optionArray = [ListModel]()
        for people in OfflinePeoples.shared.peoples {
            if let userType = people.usertype, userType.lowercased() != UserType.Visitor {
                var  fullName = ""
                if let firstName = people.firstname {
                    fullName = firstName
                }
                if let lastName = people.lastname {
                    if fullName == "" {
                        fullName = lastName
                    } else {
                        fullName = fullName + " " + lastName
                    }
                }
                optionArray.append(ListModel(listId: people.peopleid, listImage: nil, listName: fullName))
            }
        }
        self.whomToMeetDropDownTextField.optionArray = optionArray
    }
    
    func setPurposeOfVisitDropDown() {
        if Utilities.shared.isPadDevice() {
            self.purposeOfVisitDropDownTextField.arrowSize = 22.0
            self.purposeOfVisitDropDownTextField.rowHeight = 50.0
            self.purposeOfVisitDropDownTextField.listHeight = self.purposeOfVisitDropDownTextField.rowHeight * 4
            self.purposeOfVisitDropDownTextField.paddingLeft = 15
            self.purposeOfVisitDropDownTextField.paddingRight = 50
        } else {
            self.purposeOfVisitDropDownTextField.arrowSize = 15.0
            self.purposeOfVisitDropDownTextField.rowHeight = 40.0
            self.purposeOfVisitDropDownTextField.listHeight = self.purposeOfVisitDropDownTextField.rowHeight * 4
            self.purposeOfVisitDropDownTextField.paddingLeft = 12
            self.purposeOfVisitDropDownTextField.paddingRight = 40
        }
        self.purposeOfVisitDropDownTextField.didSelectCompletion = { list in
            self.purposeOfVisitData = list
        }
        self.setPurposeOfVisitData()
    }
    
    func setPurposeOfVisitData() {
        var optionArray = [ListModel]()
        
        optionArray.append(ListModel(listId: nil, listImage: nil, listName: "Business meeting"))
        optionArray.append(ListModel(listId: nil, listImage: nil, listName: "Meeting with an employee"))
        optionArray.append(ListModel(listId: nil, listImage: nil, listName: "Job Interview"))
        optionArray.append(ListModel(listId: nil, listImage: nil, listName: "Training/Workshop/Consultation"))
        optionArray.append(ListModel(listId: nil, listImage: nil, listName: "Customer visit"))
        optionArray.append(ListModel(listId: nil, listImage: nil, listName: "Maintenance or Repair"))
        optionArray.append(ListModel(listId: nil, listImage: nil, listName: "Delivery or Pickup"))
        optionArray.append(ListModel(listId: nil, listImage: nil, listName: "Employee onboarding"))
        optionArray.append(ListModel(listId: nil, listImage: nil, listName: "Others"))
        
        self.purposeOfVisitDropDownTextField.optionArray = optionArray
    }
    
    // MARK: Set Logo
    func setLogo() {
        self.logoImageView.image = Utilities.shared.getAppLogo()
    }
    
    // MARK: Data Bind
    func dataBind() {
        self.selfieImageView.image = self.selfieImage
        if let visitor = self.visitor {
            self.firstNameView.backgroundColor = .lightGrayBackground.withAlphaComponent(0.2)
            self.firstNameTextField.isEnabled = false
            self.firstNameTextField.isUserInteractionEnabled = false
            self.lastNameView.backgroundColor = .lightGrayBackground.withAlphaComponent(0.2)
            self.lastNameTextField.isEnabled = false
            self.lastNameTextField.isUserInteractionEnabled = false
            self.phoneNumberView.backgroundColor = .lightGrayBackground.withAlphaComponent(0.2)
            self.phoneNumberTextField.isEnabled = false
            self.phoneNumberTextField.isUserInteractionEnabled = false
            self.emailIdView.backgroundColor = .lightGrayBackground.withAlphaComponent(0.2)
            self.emailIdTextField.isEnabled = false
            self.emailIdTextField.isUserInteractionEnabled = false
            if let firstName = visitor.firstname {
                self.firstNameTextField.text = firstName
            }
            if let lastName = visitor.lastname {
                self.lastNameTextField.text = lastName
            }
            if let phone = visitor.phone {
                self.phoneNumberTextField.text = phone
            }
            if let email = visitor.email {
                self.emailIdTextField.text = email
            }
        }
    }
    
    // MARK: - Button Action
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func whomToMeetAction(_ sender: Any) {
        self.view.endEditing(true)
        if let controller = self.getViewController(storyboard: Storyboard.listView, id: "ListViewViewController") as? ListViewViewController {
            controller.searchPlaceholder = Message.SearchWhomToMeet
            controller.delegate = self
            self.present(controller, animated: true)
        }
    }
    
    @IBAction func submitAction(_ sender: Any) {
        self.view.endEditing(true)
        if !APIManager.isConnectedToInternet() {
            self.showAlert(text: Message.PleaseCheckYourInternetConnection)
        } else if (self.phoneNumberTextField.text?.count ?? 0 < 10) && (self.visitor == nil) {
            self.showAlert(text: Validation.PhoneNumberEnter)
        } else if (self.firstNameTextField.text?.count ?? 0 < 1) && (self.visitor == nil) {
            self.showAlert(text: Validation.FirstNameEnter)
        } else if (self.lastNameTextField.text?.count ?? 0 < 1) && (self.visitor == nil) {
            self.showAlert(text: Validation.LastNameEnter)
        } else if (Utilities.shared.isValidEmail(self.emailIdTextField.text ?? "") == false) && (self.visitor == nil) {
            self.showAlert(text: Validation.EmailIdValid)
        } else if self.whomToMeetData == nil {
            self.showAlert(text: Validation.WhomToMeetSelect)
        } else if self.purposeOfVisitData == nil {
            self.showAlert(text: Validation.PurposeOfVisitSelect)
        } else {
            if let firstName = self.firstNameTextField.text, let lastName = self.lastNameTextField.text, let emailId = self.emailIdTextField.text, let phoneNumber = self.phoneNumberTextField.text, let whomToMeetData = self.whomToMeetData, let whomToMeetId = whomToMeetData.listId, let purposeOfVisitData = self.purposeOfVisitData, let purposeOfVisit = purposeOfVisitData.listName, self.embeddings != "" {
                VisitorViewModel().createVisitor(firstName: firstName, lastName: lastName, emailId: emailId, phoneNumber: phoneNumber, whomToMeetId: whomToMeetId, purposeOfVisit: purposeOfVisit, embeddings: self.embeddings, isLoader: true) { data in
                    if let data = data, let status = data.status, let message = data.message {
                        if status.lowercased() == APIStatus.Success {
                            if let controller = self.getViewController(storyboard: Storyboard.visitorSuccess, id: "VisitorSuccessViewController") as? VisitorSuccessViewController {
                                self.navigationController?.pushViewController(controller, animated: true)
                            }
                        } else {
                            self.showAlert(text: message)
                        }
                    } else {
                        self.showAlert(text: Validation.SomethingWrong)
                    }
                }
            } else {
                self.showAlert(text: Validation.SomethingWrong)
            }
        }
    }
}

extension VisitorDetailsViewController: ListViewDelegate {
    func getListData(people: PeoplesModel) {
        self.whomToMeetTextField.text = "\(people.firstname ?? "") \(people.lastname ?? "")"
    }
}

extension VisitorDetailsViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let currentString: NSString = (textField.text ?? "") as NSString
        let newString: NSString = currentString.replacingCharacters(in: range, with: string) as NSString
        
        if textField == self.firstNameTextField || textField == self.lastNameTextField {
            let maxLength = 60
            return newString.length <= maxLength
        } else if textField == self.phoneNumberTextField {
            let maxLength = 10
            if newString.length == maxLength {
                VisitorViewModel().getVisitor(phoneNumber: newString as String, isLoader: true) { data in
                    if let data = data, let result = data.result, let visitor = result.first {
                        textField.resignFirstResponder()
                        if let visitorImage = visitor.visitorImage, self.embeddings != "" {
                            if ParavisionServices.shared.identify(embeddingsOne: visitorImage, embeddingsTwo: self.embeddings) {
                                self.visitor = visitor
                                self.dataBind()
                            } else {
                                self.showAlert(text: Message.VisitorVerificationMessage) {
                                    textField.text = ""
                                    textField.becomeFirstResponder()
                                }
                            }
                        } else {
                            self.visitor = visitor
                            self.dataBind()
                        }
                    }
                }
            }
            return (Int(newString as String) != nil || newString.length == 0) && newString.length <= maxLength
        }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.emailIdTextField {
            if (Utilities.shared.isValidEmail(self.emailIdTextField.text ?? "") == true) && (self.visitor == nil) {
                if let email = self.emailIdTextField.text {
                    VisitorViewModel().getVisitor(email: email, isLoader: false) { data in
                        if let data = data, let result = data.result, let visitor = result.first {
                            if let visitorImage = visitor.visitorImage, self.embeddings != "" {
                                if ParavisionServices.shared.identify(embeddingsOne: visitorImage, embeddingsTwo: self.embeddings) {
                                    self.visitor = visitor
                                    self.dataBind()
                                } else {
                                    self.view.endEditing(true)
                                    self.showAlert(text: Message.VisitorVerificationEmailMessage) {
                                        self.emailIdTextField.text = ""
                                        self.emailIdTextField.becomeFirstResponder()
                                    }
                                }
                            } else {
                                self.visitor = visitor
                                self.dataBind()
                            }
                        }
                    }
                }
            }
        }
    }
}
