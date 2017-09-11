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
    var endTime : TimeInterval?
    var timeDifference : TimeInterval
    var trimmedUrl : URL?
    var trimmedFilename: String?
    var peopleSpeaking = [(name: String, startTime: TimeInterval, endTime: TimeInterval)]()
    var notes = [(note: String, time: TimeInterval)]()
    
    init(startTime: TimeInterval, timeDifference: TimeInterval) {
        self.startTime = startTime
        self.timeDifference = timeDifference
    }
    
    func trimAudio(url: URL, name: String, reference: ProcessAudioViewController) {
        let input = AVAsset(url: url)
        
        let exportSession = AVAssetExportSession(asset: input, presetName: AVAssetExportPresetPassthrough)
        
        guard let endTime = self.endTime else {
            // we gots a problem
            return
        }
        
        var startTime = self.startTime - self.timeDifference
        if startTime < 0 {
            startTime = TimeInterval(0.0)
        }
        print("start time", startTime)
        
        let startOfTrim = CMTimeMake(Int64(self.startTime), 1)
        let endOfTrim = CMTimeMake(Int64(endTime), 1)
        let exportTimeRange = CMTimeRangeFromTimeToTime(startOfTrim, endOfTrim)
        
        exportSession?.outputFileType = AVFileTypeWAVE
        exportSession?.timeRange = exportTimeRange
        
        let startTimeDescription = startTime.description.replacingOccurrences(of: ".", with: "")
        let endTimeDescription = endTime.description.replacingOccurrences(of: ".", with: "")
        
        // https://stackoverflow.com/questions/29707622/swift-compiler-error-expression-too-complex-on-a-string-concatenation
        let filename = "\(name)-\(startTimeDescription)-\(endTimeDescription).wav"
        self.trimmedFilename = filename
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.trimmedUrl = documentsDirectory.appendingPathComponent(filename)
        // TODO: check if filename is already in use. Tried this but run into race condition, creates
        // file before it started export. Not sure if this is a problem though as using start and
        // end time
        exportSession?.outputURL = self.trimmedUrl
        
        exportSession?.exportAsynchronously(completionHandler: {
            if AVAssetExportSessionStatus.completed == exportSession?.status {
                reference.trimmedExcerpt(success: true)
            } else {
                reference.trimmedExcerpt(success: false)
            }
        })
    }
    
    func toJSON() -> Parameters {
//        var startTime : TimeInterval
//        var endTime : TimeInterval?
//        var timeDifference : TimeInterval
//        var trimmedUrl : URL?
//        var trimmedFilename: String?
//        var peopleSpeaking = [(name: String, startTime: TimeInterval, endTime: TimeInterval)]()
//        var notes = [(note: String, time: TimeInterval)]()
        
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
            "startTime": self.startTime,
            "endTime": self.endTime ?? 0,
            "timeDifference": self.timeDifference,
            "peopleSpeaking": peopleSpeakingJson,
            "notes": notesJson,
        ]
    }
}
