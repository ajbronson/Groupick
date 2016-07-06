//
//  SearchPlaylistTableViewController.swift
//  Groupic
//
//  Created by AJ Bronson on 6/17/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import UIKit

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
        resultsViewController.delegate = self
        resultsViewController.resultPlaylists = [TempPlaylist]()
        for i in 0...text.characters.count {
            resultsViewController.resultPlaylists.append(TempPlaylist(name: "This is a Test Playlist - \(i + 1)"))
        }
        resultsViewController.resultPlaylists.append(TempPlaylist(name: "A public playlist", passcode: nil, id: NSUUID().UUIDString, dateCreated: NSDate()))
        resultsViewController.tableView.reloadData()
        //UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        //UIApplication.sharedApplication().networkActivityIndicatorVisible = false
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
