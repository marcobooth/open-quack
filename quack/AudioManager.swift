//
//  AudioManager.swift
//  quack
//
//  Created by Marco Booth on 10/09/2017.
//  Copyright © 2017 Marco Booth. All rights reserved.
//

import Foundation
import AVFoundation

struct AudioManager {
    static let sharedInstance = AudioManager()
    
    func setSessionRecord() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(AVAudioSessionCategoryRecord)
        } catch {
            print("could not set session category")
            print(error.localizedDescription)
        }
        
        do {
            try session.setActive(true)
        } catch {
            print("could not make session active")
            print(error.localizedDescription)
        }
    }
    
    func unsetSessionRecord() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false)
        } catch {
            print("could not make session inactive")
            print(error.localizedDescription)
        }
    }
    
    func deleteAudioFile(url : URL?) {
        guard let fileToDelete = url else {
            print("file was not deleted")
            return
        }
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: fileToDelete)
        } catch {
            print(error)
        }
    }
}
