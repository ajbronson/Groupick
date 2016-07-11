//
//  AppDelegate.swift
//  Groupic
//
//  Created by AJ Bronson on 6/17/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import UIKit
import AVFoundation
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        UIApplication.sharedApplication().registerForRemoteNotifications()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch {
            print("Error with AVAudio session")
        }
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        guard let notificationInfo = userInfo as? [String: NSObject] else { return }
        let notification = CKQueryNotification(fromRemoteNotificationDictionary: notificationInfo)
        
        if let subID = notification.subscriptionID where subID.containsString("Delete_Playlist_") {
            let subscriptionID = subID.substringFromIndex(subID.startIndex.advancedBy(16))
            if let playlist = PlaylistController.sharedController.playlistWithID(subscriptionID) {
                if let root = UIApplication.topViewController() as? SongsTableViewController {
                    if root.playlist?.id == subscriptionID {
                      root.navigationController?.popViewControllerAnimated(true)
                    }
                } else if let root = UIApplication.topViewController() as? SearchSongTableViewController {
                    if root.playlist?.id == subscriptionID {
                        root.navigationController?.popViewControllerAnimated(true)?.navigationController?.popViewControllerAnimated(true)
                    }
                } else if let root = UIApplication.topViewController() as? UISearchController, let rootView = root.searchResultsController as? SearchSongResultsTableViewController {
                    if rootView.playlist?.id == subscriptionID {
                        root.dismissViewControllerAnimated(true, completion: {
                            if let newRoot = UIApplication.topViewController() as? SearchSongTableViewController {
                                newRoot.navigationController?.popViewControllerAnimated(true)?.navigationController?.popViewControllerAnimated(true)
                            }
                        })
                    }
                }
                PlaylistController.sharedController.deletePlaylist(playlist)
            }
        } else if let recordID = notification.recordID {
            CloudKitManager.sharedManager.fetchRecordWithID(recordID, completion: { (record, error) in
                if let record = record {
                    let song = Song(record: record)
                    let vote = Vote(record: record)
                    PlaylistController.sharedController.save()
                    if let song = song {
                        if let root = UIApplication.topViewController() as? SongsTableViewController {
                            if root.playlist?.id == song.playlist.id {
                                root.addCKSong(song)
                            }
                        }
                        SongController.sharedController.addSubscriptionToSongVotes(song, completion: { (success, error) in
                            if let error = error {
                                print("error subscribing to vote - \(error.localizedDescription)")
                            }
                        })
                    } else if let vote = vote {
                        if let root = UIApplication.topViewController() as? SongsTableViewController {
                            if root.playlist?.id == vote.song.playlist.id {
                                root.addCKVote(vote)
                            }
                        }
                    }
                }
            })
        }
        
        completionHandler(UIBackgroundFetchResult.NewData)
    }
    
}

extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.sharedApplication().keyWindow?.rootViewController) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController {
            let moreNavigationController = tab.moreNavigationController
            
            if let top = moreNavigationController.topViewController where top.view.window != nil {
                return topViewController(top)
            } else if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        
        return base
    }
}

