//
//  MusicController.swift
//  Groupic
//
//  Created by AJ Bronson on 6/28/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import Foundation
import MediaPlayer
import UIKit

class MusicController: NSObject {
    
    static let sharedController = MusicController()
    
    let controller = MPMusicPlayerController()
    
    var delegate: nextButtonProtocol?
    
    override init() {
        super.init()
        let remoteCenter = MPRemoteCommandCenter.sharedCommandCenter()
        remoteCenter.pauseCommand.enabled = true
        remoteCenter.playCommand.enabled = true
        remoteCenter.nextTrackCommand.enabled = true
        remoteCenter.togglePlayPauseCommand.enabled = true
        remoteCenter.playCommand.addTarget(self, action: #selector(play))
        remoteCenter.pauseCommand.addTarget(self, action: #selector(pause))
        remoteCenter.nextTrackCommand.addTarget(self, action: #selector(nextButtonClicked))
        remoteCenter.togglePlayPauseCommand.addTarget(self, action: #selector(pause))
        controller.beginGeneratingPlaybackNotifications()
    }
    
    
    func setQueue(trackIDs: [String]) {
        
        controller.setQueueWithStoreIDs(trackIDs)
    }
    
    func play() {
        NSLog("play")
        controller.play()
    }
    
    func pause() {
        NSLog("pause")
        controller.pause()
    }
    
    func nextSong() {
        NSLog("next song")
        controller.skipToNextItem()
    }
    
    func stop() {
        controller.stop()
    }
    
    func nextButtonClicked() {
        delegate?.nextButtonClicked()
    }

}
protocol nextButtonProtocol {
    func nextButtonClicked()
}