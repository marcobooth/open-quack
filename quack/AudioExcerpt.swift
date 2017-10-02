//
//  AudioExcerpt.swift
//  quack
//
//  Created by Marco Booth on 31/08/2017.
//  Copyright © 2017 Marco Booth. All rights reserved.
//

import Foundation
import AVFoundation
import Alamofire

class AudioExcerpt {
    
    var startTime : TimeInterval
    var backdatedTime: TimeInterval
    var endTime : TimeInterval?
    var timeDifference : TimeInterval
    var trimmedUrl : URL?
    var trimmedFilename: String?
    var peopleSpeaking = [(name: String, startTime: TimeInterval, endTime: TimeInterval)]()
    var notes = [(note: String, time: TimeInterval)]()
    
    init(startTime: TimeInterval, timeDifference: TimeInterval) {
        self.startTime = startTime
        self.timeDifference = timeDifference
        
        self.backdatedTime = self.startTime - self.timeDifference
        if backdatedTime < 0 {
            self.backdatedTime = TimeInterval(0.0)
        }
    }
    
    func trimAudio(url: URL, name: String, reference: ProcessAudioViewController) {
        guard let endTime = self.endTime else {
            // we gots a problem
            return
        }
        
        let startOfTrim = CMTimeMake(Int64(self.backdatedTime * 100), 100)
        let endOfTrim = CMTimeMake(Int64(endTime * 100), 100)
        
        let exportSession = AVAssetExportSession(asset: AVAsset(url: url), presetName: AVAssetExportPresetPassthrough)
        exportSession?.outputFileType = AVFileTypeWAVE
        exportSession?.timeRange = CMTimeRangeFromTimeToTime(startOfTrim, endOfTrim)
        let excertStartDesc = self.backdatedTime.description.replacingOccurrences(of: ".", with: "")
        let excertEndDesc = endTime.description.replacingOccurrences(of: ".", with: "")
        
        // https://stackoverflow.com/questions/29707622/swift-compiler-error-expression-too-complex-on-a-string-concatenation
        let filename = "\(name)-\(excertStartDesc)-\(excertEndDesc).wav"
        self.trimmedFilename = filename
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.trimmedUrl = documentsDirectory.appendingPathComponent(filename)
        
        // TODO: check if filename is already in use. Tried this but run into race condition, creates
        // file before it started export. Not sure if this is a problem though as using start and
        // end time
        exportSession?.outputURL = self.trimmedUrl
        
        exportSession?.exportAsynchronously(completionHandler: {
            if exportSession?.status == AVAssetExportSessionStatus.completed {
                reference.trimmedExcerpt(success: true)
            } else {
                reference.trimmedExcerpt(success: false)
            }
        })
    }
    
    func toJSON() -> Parameters {
        let peopleSpeakingJson = self.peopleSpeaking.map { (name, startTime, endTime) in
            return [
                "name": name,
                "startTime": startTime,
                "endTime": endTime,
            ]
        }
        
        let notesJson = self.notes.map { (note, time) in
            return [
                "text": note,
                "timestamp": time,
            ]
        }
        
        return [
            "backdatedTime": self.backdatedTime,
            "startTime": self.startTime,
            "endTime": self.endTime ?? 0,
            "timeDifference": self.timeDifference,
            "peopleSpeaking": peopleSpeakingJson,
            "notes": notesJson,
        ]
    }
}
