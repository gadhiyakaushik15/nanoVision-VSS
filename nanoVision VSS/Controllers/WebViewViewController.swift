//
//  WebViewViewController.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 06/05/24.
//

import UIKit
import WebKit

class WebViewViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var innerView: UIView!
    
    var url : URL!
    var webView: WKWebView!
    var strTitle = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configUI()
        self.setLogo()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setUpWebView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        LocalDataService.shared.syncCompleted = {
            DispatchQueue.main.async() {
                self.setLogo()
            }
            if Utilities.shared.isMQTTEnabled() {
                MQTTManager.shared().checkRelayChange()
            }
        }
    }
    
    // MARK: Config UI
    func configUI() {
        self.titleLabel.text = self.strTitle
        Utilities.shared.addSideRadiusWithOpacity(view: self.lineView, radius: 0, shadowRadius: 4, opacity: 1, shadowOffset: CGSize(width: 0 , height: 4), shadowColor: UIColor.black.withAlphaComponent(0.25), corners: [])
        
        if Utilities.shared.isPadDevice() {
            let backConfig = UIImage.SymbolConfiguration(
                pointSize: 26, weight: .heavy, scale: .large)
            let backImage = UIImage(systemName: "arrow.backward", withConfiguration: backConfig)
            self.backButton.setImage(backImage, for: .normal)
        } else {
            let backConfig = UIImage.SymbolConfiguration(
                pointSize: 18, weight: .heavy, scale: .medium)
            let backImage = UIImage(systemName: "arrow.backward", withConfiguration: backConfig)
            self.backButton.setImage(backImage, for: .normal)
        }
    }
    
    // MARK: Set Logo
    func setLogo() {
        self.logoImageView.image = Utilities.shared.getAppLogo()
    }
    
    func setUpWebView() {
        let webConfiguration = WKWebViewConfiguration()
        self.webView = WKWebView(frame: self.innerView.bounds, configuration: webConfiguration)
        self.webView.navigationDelegate = self
        self.webView.scrollView.bounces = false
        self.webView.scrollView.bouncesZoom = false
        self.webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.innerView.addSubview(  self.webView)
        Utilities.shared.showSVProgressHUD()
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 5)
        self.webView.load(request)
    }

    // MARK: - Button Action
    @IBAction func backAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
}

extension WebViewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Utilities.shared.dismissSVProgressHUD()
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Utilities.shared.dismissSVProgressHUD()
        self.showAlert(text: error.localizedDescription)
    }
}
