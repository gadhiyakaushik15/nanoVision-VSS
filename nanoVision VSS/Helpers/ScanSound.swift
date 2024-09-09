//
//  ScanSound.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 20/05/24.
//

import AudioToolbox

class ScanSound {

    var soundEffect: SystemSoundID = 0
    
    init(name: String, type: String) {
        if let path  = Bundle.main.path(forResource: name, ofType: type) {
            let pathURL = NSURL(fileURLWithPath: path)
            AudioServicesCreateSystemSoundID(pathURL as CFURL, &soundEffect)
        }
    }

    func play() {
        if soundEffect != 0 {
            AudioServicesPlaySystemSound(soundEffect)
        }
    }
}
