//
//  SearchSongTableViewController.swift
//  Groupic
//
//  Created by AJ Bronson on 6/17/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import UIKit

class SearchSongTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {

    var playlist: Playlist?
    var searchController: UISearchController?
    var songs = [Song]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpSearchController()
        self.navigationController?.toolbarHidden = true
    }
    
    
    func setUpSearchController() {
        let resultsController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("storySearchResultsView")
        searchController = UISearchController(searchResultsController: resultsController)
        guard let searchController = searchController else { return }
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search"
        searchController.definesPresentationContext = true
        searchController.searchBar.delegate = self
        searchController.searchBar.scopeButtonTitles = ["Song", "Artist"]
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchController?.searchBar.showsScopeBar = false
        navigationController?.popViewControllerAnimated(false)
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        guard let text = searchController.searchBar.text?.lowercaseString,
            let resultsViewController = searchController.searchResultsController as? SearchSongResultsTableViewController  where text.characters.count > 0 else { return }
        resultsViewController.playlist = playlist
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        var type: SongController.searchType
        if searchController.searchBar.selectedScopeButtonIndex == 0 {
            type = .song
        } else {
            type = .artist
        }
        SongController.sharedController.fetchSongsWithTerm(text, type: type) { (songs) in
            dispatch_async(dispatch_get_main_queue(), { 
                resultsViewController.resultsArray = songs
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            })
        }
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        guard let searchBar = self.searchController?.searchBar else { return UIView() }
        

        header.addSubview(searchBar)
        return header
    }


    // MARK: - Table view data source


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("addSongCell", forIndexPath: indexPath) as? AddSongTableViewCell
        return cell ?? UITableViewCell()
    }
 
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        guard let searchController = searchController else { return }
        updateSearchResultsForSearchController(searchController)
    }
    

    

}


