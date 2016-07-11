//
//  SearchPlaylistTableViewController.swift
//  Groupic
//
//  Created by AJ Bronson on 6/17/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import UIKit
import CloudKit

class SearchPlaylistTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate, dismissProtocol {

    var searchController: UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpSearchController()
        self.navigationController?.toolbarHidden = true
    }

    func setUpSearchController() {
        let resultsController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("playlistResultsView")
        searchController = UISearchController(searchResultsController: resultsController)
        guard let searchController = searchController else { return }
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search"
        searchController.definesPresentationContext = true
        searchController.searchBar.delegate = self
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        navigationController?.popViewControllerAnimated(false)
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        guard let text = searchController.searchBar.text?.lowercaseString,
            let resultsViewController = searchController.searchResultsController as? SearchPlaylistResultsTableViewController  where text.characters.count > 0 else { return }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        resultsViewController.delegate = self
        resultsViewController.resultPlaylists = [TempPlaylist]()
        searchCloudKit(text) { (playlists) in
            dispatch_async(dispatch_get_main_queue(), { 
                resultsViewController.resultPlaylists = playlists
                resultsViewController.tableView.reloadData()
            })
        }
    }
    
    func searchCloudKit(searchText: String, completion: ([TempPlaylist]) -> Void) {
        if let userRecord = UserController.getUser()?.cloudKitRecord {
            let creatorReference = CKReference(record: userRecord, action: .None)
            let predicate = NSPredicate(format: "creator != %@ && self contains %@", argumentArray: [creatorReference, searchText])
            var arrayPlaylist = [TempPlaylist]()
            CloudKitManager.sharedManager.fetchRecordsWithType("Playlist", predicate: predicate, recordFetchedBlock: nil) { (records, error) in
                if let records = records {
                    for record in records {
                        let tempPlaylist = TempPlaylist(record: record)
                        if let tempPlaylist = tempPlaylist {
                            arrayPlaylist.append(tempPlaylist)
                        }
                    }
                }
                completion(arrayPlaylist)
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        }
    }

    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        guard let searchBar = self.searchController?.searchBar else { return UIView() }
        header.addSubview(searchBar)
        return header
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }


    @IBAction func cancelButtonTapped(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    func dismiss() {
        navigationController?.popViewControllerAnimated(true)
    }
}
