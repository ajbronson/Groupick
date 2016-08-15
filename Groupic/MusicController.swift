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

class MusicController: NSObject, AVAudioPlayerDelegate {
    
    static let sharedController = MusicController()
    
    let controller = MPMusicPlayerController.systemMusicPlayer()
    
    var delegate: nextButtonProtocol?

    var ignoreCount = 0
    
    override init() {
        super.init()
        controller.beginGeneratingPlaybackNotifications()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MusicController.songNotification(_:)), name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification, object: nil)
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
    }
    
    func incrementIgnoreCount(by: Int) {
        ignoreCount = ignoreCount + by
    }
    
    //http://stackoverflow.com/questions/25812268/core-data-error-exception-was-caught-during-core-data-change-processing
    
    func songNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo, reasonValue = userInfo["MPMusicPlayerControllerNowPlayingItemPersistentIDKey"] as? Int {
            if ignoreCount > 0 {
                if ignoreCount > 3 {
                    ignoreCount = 3
                }
                ignoreCount = ignoreCount - 1
                if reasonValue != 0 && ignoreCount == 1 {
                    ignoreCount = 0
                }
            } else {
                if reasonValue == 0 {
                    delegate?.nextButtonClicked()
                    ignoreCount = ignoreCount - 1
                }
            }
        }
    }
    
    func setQueue(trackIDs: [String]) {
        controller.setQueueWithStoreIDs(trackIDs)
    }
    
    func play() {
        controller.play()
    }
    
    func pause() {
        controller.pause()
    }
    
    func nextSong() {
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