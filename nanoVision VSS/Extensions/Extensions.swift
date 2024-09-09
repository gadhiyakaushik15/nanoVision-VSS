//
//  Extensions.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 04/04/24.
//

import Foundation
import UIKit
import AVFoundation
import VideoToolbox

extension UIView {
    @IBInspectable var cornerRadiusV: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    @IBInspectable var borderWidthV: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    @IBInspectable var borderColorV: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    func resizeTextElements() {
        for i in 0 ..< self.subviews.count {
            let subview : AnyObject = self.subviews[i]
            if subview is UILabel {
                (subview as! UILabel).font = adjustedFontForScreenSize((subview as! UILabel).font)
            } else if subview is UIButton {
                (subview as! UIButton).titleLabel?.font = adjustedFontForScreenSize((subview as! UIButton).titleLabel?.font)
            } else if subview is UITextView {
                (subview as! UITextView).font = adjustedFontForScreenSize((subview as! UITextView).font)
            } else if subview is UITextField {
                (subview as! UITextField).font = adjustedFontForScreenSize((subview as! UITextField).font)
            } else if subview is UIView {
                (subview as! UIView).resizeTextElements()
            }
        }
    }
    
    func addBlurEffect() {
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(blurEffectView)
    }
}

extension UIImage {
    convenience init?(buffer: CMSampleBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(buffer.imageBuffer!, options: nil, imageOut: &cgImage)
        guard let cgImage = cgImage else {
            return nil
        }
        self.init(cgImage: cgImage)
    }
//    
//    func compressTo(mb: Int) -> UIImage? {
//        let sizeInBytes = mb * 1024 * 1024
//        var needCompress = true
//        var imgData: Data?
//        var compressingValue: CGFloat = 1.0
//        while needCompress {
//            if let data: Data = self.jpegData(compressionQuality: compressingValue) {
//                if data.count <= sizeInBytes {
//                    needCompress = false
//                    imgData = data
//                } else {
//                    if compressingValue <= 0 {
//                        compressingValue = 1.0
//                    } else {
//                        compressingValue -= 0.1
//                    }
//                }
//            }
//        }
//        
//        if let data = imgData {
//            return UIImage(data: data)
//        }
//        return nil
//    }
    
    func toBase64String() -> String {
        return "data:image/png;base64,\(self.pngData()?.base64EncodedString() ?? "")"
    }
}

extension Data {
    func toBase64String() -> String {
        return "data:image/png;base64,\(self.base64EncodedString())"
    }
}

extension UIViewController {
    func showAlert(text: String) {
        let alert = UIAlertController(title: Message.Error, message: text, preferredStyle: .alert)
        alert.addAction(.init(title: Message.Ok, style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    func showAlert(text: String, completion: @escaping () -> (Void)) {
        let alert = UIAlertController(title: Message.Error, message: text, preferredStyle: .alert)
        alert.addAction(.init(title: Message.Ok, style: .default, handler: { alert in
            completion()
        }))
        present(alert, animated: true)
    }
    
    
    func getViewController(storyboard: UIStoryboard?, id : String) -> UIViewController? {
        if let controller = storyboard?.instantiateViewController(withIdentifier: id) {
            return controller
        } else {
            return nil
        }
    }
}

extension Date {
    var timestamp: String  {
        return "\(Int64(self.timeIntervalSince1970 * 1000))"
    }
    
    func toLocalTime() -> Date {
            let timezone = TimeZone.current
            let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
            return Date(timeInterval: seconds, since: self)
        }
}

extension String {
    func convertBase64StringToImage () -> UIImage {
        if let imageData = Data.init(base64Encoded: self, options: .init(rawValue: 0)), let image = UIImage(data: imageData) {
            return image
        } else {
            return UIImage()
        }
    }
    
    func condenseWhitespace() -> String {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
}

extension UILabel {
    func setHTMLFromString(htmlText: String, isCenter: Bool = false) {
        var modifiedFont = String(format:"<span style=\"font-family: '-apple-system'; font-weight: bold; font-size: \(self.font!.pointSize); color: \(self.textColor.hex())\">%@</span>", htmlText)
        if isCenter {
            modifiedFont = "<center>\(modifiedFont)</center>"
        }
        
        let attrStr = try! NSAttributedString(
            data: modifiedFont.data(using: .unicode, allowLossyConversion: true)!,
            options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue],
            documentAttributes: nil)

        self.attributedText = attrStr
    }
}

extension UIColor {
    func hex() -> String {
        let components = self.cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0

        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        return hexString
     }
}

func adjustedFontForScreenSize(_ font : UIFont!) -> UIFont {
    let fontName = font.fontName
    let fontPointSize = font.pointSize
    let screenWidth = UIScreen.main.bounds.width
    let adjustedFontPointSize = (screenWidth / 375) * fontPointSize
    // ratio is all proportional to 375 screen size
    return UIFont(name: fontName, size: adjustedFontPointSize)!
}

extension UIApplication {
    func currentUIWindow() -> UIWindow? {
        let connectedScenes = UIApplication.shared.connectedScenes .compactMap { $0 as? UIWindowScene }
        
        let window = connectedScenes.first?.windows.first { $0.isKeyWindow }

        return window
    }
}

extension Bundle {
    var version: String? {
        return object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    var displayName: String? {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    }
}

extension Notification.Name {
    static let stopSession = Notification.Name("StopSession")
}
