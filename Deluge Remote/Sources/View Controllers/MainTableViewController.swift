//
//  MainTableViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 11/12/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import PromiseKit
import UIKit

class MainTableViewController: UITableViewController {
    // swiftlint:disable:previous type_body_length

    enum SortKey: String, CaseIterable {
        case Name
        case State
        case Size
        case Ratio
        case DownloadSpeed = "Download Speed"
        case UploadSpeed = "Upload Speed"
        case TotalDownload = "Total Download"
        case TotalUpload = "Total Upload"
    }

    var activeSortKey = SortKey.Name
    var sortAscending = true

    // MARK: - Properties
    let byteCountFormatter = ByteCountFormatter()
    let searchController = UISearchController(searchResultsController: nil)

    var tableViewDataSource: [TableViewTorrent]?
    var filteredTableViewDataSource = [TableViewTorrent]()
    var isHostOnline: Bool = false
    var cancelNextRefresh = false
    var shouldRefresh = true

    var dataTransferTotalsView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 22))
        view.backgroundColor = UIColor.clear
        return view
    }()

    var currentUploadSpeedLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 11))
        label.font = label.font.withSize(11)
        label.text = "↑ 0 KiB/s"
        label.backgroundColor = UIColor.clear
        return label
    }()

    var currentDownloadSpeedLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 11, width: 80, height: 11))
        label.font = label.font.withSize(11)
        label.text = "↓ 0 KiB/s"
        label.backgroundColor = UIColor.clear
        return label
    }()

    var totalUploadLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 11))
        label.font = label.font.withSize(11)
        label.text = "↑ 0 KiB"
        label.backgroundColor = UIColor.clear
        return label
    }()

    var totalDownloadLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 11, width: 80, height: 11))
        label.font = label.font.withSize(11)
        label.text = "↓ 0 KiB/s"
        label.backgroundColor = UIColor.clear
        return label
    }()

    var statusHeader: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor(red: 0.0, green: 0.9, blue: 0.2, alpha: 0.85)
        if ClientManager.shared.activeClient != nil {
            label.backgroundColor = UIColor(red: 4.0/255.0, green: 123.0/255.0, blue: 242.0/255.0, alpha: 1.0)
            label.text = "Attempting Connection"
        } else {
            label.backgroundColor = UIColor.red
            label.text = "No Active Configuration"
        }

        label.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        label.textAlignment = NSTextAlignment.center
        label.autoresizingMask = UIViewAutoresizing.flexibleLeftMargin
        return label
    }()

    @IBAction func resumeAllTorrentsAction(_ sender: Any) {
        (isHostOnline == true) ? self.resumeAllTorrents() : ()
    }
    @IBAction func pauseAllTorrentsAction(_ sender: Any) {
        (isHostOnline == true) ? self.pauseAllTorrents() : ()
    }
    @IBAction func displaySortMenu(_ sender: UIBarButtonItem) {

        let title = "Sorted by: \(activeSortKey.rawValue) (\(sortAscending ? "Ascending" : "Descending"))"
        let orderAs = UIAlertAction(title: "Order As", style: .default) { [weak self] _ in
            self?.displayOrderByMenu()
        }
        let sortBy = UIAlertAction(title: "Sort By", style: .default) { [weak self] _ in
            self?.displaySortByMenu()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        showAlert(target: self, title: title, message: nil, style: .actionSheet, actionList: [sortBy, orderAs, cancel])
    }

    // MARK: - UI Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Authenticate to Client
        handleNewActiveClient()

        // Begin Data Download
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.downloadNewData()
            self.updateSessionStats()
        }

        self.initUploadDownloadLabels()
        statusHeader.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 22)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        self.navigationItem.title = ClientManager.shared.activeClient?.clientConfig.nickname ?? "Deluge Remote"
        self.tableView.accessibilityScroll(UIAccessibilityScrollDirection.down)

        NotificationCenter.default.addObserver(self, selector: #selector(self.updateHeader),
                                               name: NSNotification.Name(rawValue: "updateStatusHeader"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(self.recieveUpdateTableNotifcation),
                                               name: NSNotification.Name(rawValue: "reloadTableView"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNewActiveClient),
                                               name: Notification.Name(ClientManager.NewActiveClientNotification),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector:
            #selector(self.handleAddTorrentNotification(notification:)),
                                               name: Notification.Name("AddTorrentNotification"), object: nil)
        NewTorrentNotifier.shared.didMainTableVCCreateObserver = true

        // Setup the Search Controller
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter Torrents"
        navigationItem.searchController = searchController
        self.definesPresentationContext = true

        // Setup the Scope Bar
        searchController.searchBar.scopeButtonTitles = ["All", "Name", "Hash", "Tracker"]
        searchController.searchBar.delegate = self

    }

    override func viewWillAppear(_ animated: Bool) {
        shouldRefresh = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func initUploadDownloadLabels() {
        dataTransferTotalsView.addSubview(currentUploadSpeedLabel)
        dataTransferTotalsView.addSubview(currentDownloadSpeedLabel)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: dataTransferTotalsView)
    }

    func handleNewActiveClient() {
        print("New Client")
        self.tableViewDataSource?.removeAll()
        self.isHostOnline = false
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        self.navigationItem.title = ClientManager.shared.activeClient?.clientConfig.nickname ?? "Deluge Remote"
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateStatusHeader"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTableView"), object: nil)

        _ = ClientManager.shared.activeClient?.authenticate()
            .then { isAuthenticated -> Void in
                self.isHostOnline = isAuthenticated
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateStatusHeader"), object: nil)

                if !isAuthenticated {
                    showAlert(target: self, title: "Authentication Error", message: "Invalid Password")
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    self.downloadNewData()
                    self.updateSessionStats()
                }
            }.catch { error in
                self.isHostOnline = false
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateStatusHeader"), object: nil)
                if let error = error as? ClientError {
                    showAlert(target: self, title: "Error", message: error.domain())
                } else {
                    showAlert(target: self, title: "Error", message: error.localizedDescription)
                }
        }
    }

    func updateHeader() {
        guard ClientManager.shared.activeClient != nil else {
            self.statusHeader.text = "No Active Config"
            self.statusHeader.backgroundColor = UIColor(red: 0.98, green: 0.196, blue: 0.196, alpha: 0.85)
            return
        }
        if isHostOnline {
            self.statusHeader.text = "Host Online"
            self.statusHeader.backgroundColor = UIColor(red: 0.302, green: 0.584, blue: 0.772, alpha: 0.85)
        } else {
            self.statusHeader.text = "Host Offline"
            self.statusHeader.backgroundColor = UIColor(red: 0.98, green: 0.196, blue: 0.196, alpha: 0.85)
        }
    }

    func handleAddTorrentNotification(notification: NSNotification) {
        NewTorrentNotifier.shared.userInfo = nil
        guard
            let userInfo = notification.userInfo,
            userInfo["url"] as? URL != nil,
            userInfo["isFileURL"] as? Bool != nil
        else { return }

        if ClientManager.shared.activeClient != nil {
            self.performSegue(withIdentifier: "addTorrentSegue", sender: userInfo)
        } else {
            DispatchQueue.main.async {
                showAlert(target: self, title: "Error",
                          message: "You cannot add a torrent without an active configuration")
            }
        }
    }

    func recieveUpdateTableNotifcation() {
        if !cancelNextRefresh {
            if self.shouldRefresh && !self.tableView.isEditing &&
                !self.tableView.isDragging && !self.tableView.isDecelerating {
                print("Updating Table View")

                self.tableViewDataSource = tableViewDataSource?.sort(by: activeSortKey, ascending: sortAscending)

                self.tableView.performSelector(onMainThread: #selector(tableView.reloadData),
                                               with: nil, waitUntilDone: true)
                if isFiltering() {
                    updateSearchResults(for: searchController)
                }

            }
        } else {
            cancelNextRefresh = false
        }
    }

    func displaySortByMenu() {

        var actions = [UIAlertAction]()

        for item in SortKey.allCases {
            let action = UIAlertAction(title: item.rawValue, style: .default) { [weak self] _ in
                self?.activeSortKey = item
                NotificationCenter.default.post(name: Notification.Name("reloadTableView"), object: nil)
            }
            actions.append(action)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actions.append(cancel)

        showAlert(target: self, title: "Sort By:", message: nil, style: .actionSheet, actionList: actions)
    }

    func displayOrderByMenu() {
        let ascending = UIAlertAction(title: "Ascending", style: .default) { [weak self] _ in
            self?.sortAscending = true
            NotificationCenter.default.post(name: Notification.Name("reloadTableView"), object: nil)
        }
        let descending = UIAlertAction(title: "Descending", style: .default) { [weak self] _ in
            self?.sortAscending = false
            NotificationCenter.default.post(name: Notification.Name("reloadTableView"), object: nil)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        showAlert(target: self, title: "Order By:", message: nil, style: .actionSheet, actionList: [ascending, descending, cancel])
    }

    // MARK: - Deluge UI Wrapper Methods

    func updateSessionStats() {
        if !isHostOnline { return }
        ClientManager.shared.activeClient?.getSessionStatus().then { status -> Void in
            DispatchQueue.main.async {
                self.currentDownloadSpeedLabel.text = "↓ \(status.payload_download_rate.transferRateString())"
                self.currentUploadSpeedLabel.text = "↑ \(status.payload_upload_rate.transferRateString())"
            }
            }.catch { _ in
                DispatchQueue.main.async {
                    self.currentDownloadSpeedLabel.text = "↓ 0 KiB/s"
                    self.currentUploadSpeedLabel.text = "↑ 0 KiB/s"
                }
        }
    }

    func downloadNewData() {
        print("Attempting to get all torrents")
        if !isHostOnline { return }
        ClientManager.shared.activeClient?.getAllTorrents().then { tableViewData -> Void in
            DispatchQueue.main.async {
                print("Torrent Data Successfully Downloaded")
                self.tableViewDataSource = tableViewData
                NotificationCenter.default.post(name: Notification.Name("reloadTableView"), object: nil)
            }
            }.catch { error in
                self.isHostOnline = false
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateStatusHeader"), object: nil)
                if let error = error as? ClientError {
                    print(error.domain())
                    showAlert(target: self, title: "Error", message: error.domain())
                } else {
                    print(error.localizedDescription)
                }
        }
    }

    func pauseAllTorrents() {
        ClientManager.shared.activeClient?.pauseAllTorrents { result in
            switch result {
            case .success: print("All Torrents Paused")
            case .failure(let error): print(error)
            }
        }
    }

    func resumeAllTorrents() {
        ClientManager.shared.activeClient?.resumeAllTorrents { result in
            switch result {
            case .success: print("All Torrents Resumed")
            case .failure(let error): print(error)
            }
        }
    }

    func removeTorrent(withHash hash: String, removeData: Bool, onSuccess: @escaping () -> Void) {
        ClientManager.shared.activeClient?.removeTorrent(withHash: hash, removeData: removeData).then { _ -> Void in
            onSuccess()
            }.catch { error in
                if let error = error as? ClientError {
                    showAlert(target: self, title: "Error", message: error.domain())
                } else {
                    showAlert(target: self, title: "Error", message: error.localizedDescription)
                }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 22
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.shouldRefresh ? self.statusHeader : nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableViewDataSource = tableViewDataSource else {
            return 0
        }

        if isFiltering() {
            return filteredTableViewDataSource.count
        }
        return tableViewDataSource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let tableViewDataSource = tableViewDataSource,
            let cell = tableView.dequeueReusableCell(withIdentifier: "mainTableViewCell", for: indexPath)
                as? MainTableViewCell
            else {
                return tableView.dequeueReusableCell(withIdentifier: "mainTableViewCell", for: indexPath)
        }

        let currentItem: TableViewTorrent
        if isFiltering() {
            currentItem = filteredTableViewDataSource[indexPath.row]
        } else {
            currentItem = tableViewDataSource[indexPath.row]
        }

        cell.nameLabel.text = currentItem.name
        cell.progressBar.setProgress(Float(currentItem.progress/100), animated: true)
        cell.currentStatusLabel.text = currentItem.state
        cell.downloadSpeedLabel.text =
        "\(byteCountFormatter.string(fromByteCount: Int64(currentItem.download_payload_rate))) ↓"
        cell.uploadSpeedLabel.text =
        "↑ \(byteCountFormatter.string(fromByteCount: Int64(currentItem.upload_payload_rate)))"
        cell.torrentHash = currentItem.hash
        if currentItem.eta == 0 {
            cell.etaLabel.text = "\(currentItem.ratio.roundTo(places: 3))"
        } else {
            cell.etaLabel.text = String(currentItem.eta)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        cancelNextRefresh = false
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // swiftlint:disable:next line_length
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            // handle delete (by removing the data from your array and updating the tableview)
            if let cell = tableView.cellForRow(at: indexPath) as? MainTableViewCell {

                let deleteTorrent = UIAlertAction(title: "Delete Torrent", style: .default) { _ in
                    self.removeTorrent(withHash: cell.torrentHash, removeData: false) {
                        DispatchQueue.main.async {
                            if self.isFiltering() {
                                self.tableViewDataSource?.removeAll {
                                    $0 == self.filteredTableViewDataSource[indexPath.row]
                                }
                                self.filteredTableViewDataSource.remove(at: indexPath.row)
                                tableView.deleteRows(at: [indexPath], with: .fade)
                            } else {
                                self.tableViewDataSource?.remove(at: indexPath.row)
                                tableView.deleteRows(at: [indexPath], with: .fade)
                            }
                            self.tableView.setEditing(false, animated: true)
                        }
                    }
                }

                let deleteTorrentWithData = UIAlertAction(title: "Delete Torrent with Data", style: .default) { _ in
                    self.removeTorrent(withHash: cell.torrentHash, removeData: true) {
                        DispatchQueue.main.async {
                            if self.isFiltering() {
                                self.tableViewDataSource?.removeAll {
                                    $0 == self.filteredTableViewDataSource[indexPath.row]
                                }
                                self.filteredTableViewDataSource.remove(at: indexPath.row)
                                tableView.deleteRows(at: [indexPath], with: .fade)
                            } else {
                                self.tableViewDataSource?.remove(at: indexPath.row)
                                tableView.deleteRows(at: [indexPath], with: .fade)
                            }
                            self.tableView.setEditing(false, animated: true)
                        }
                    }

                }
                let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                    self.tableView.setEditing(false, animated: true)
                }

                showAlert(target: self, title: "Remove the selected Torrent?",
                          style: .alert, actionList: [deleteTorrent, deleteTorrentWithData, cancel])
            }
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailedTorrentViewSegue" {
            if let destination = segue.destination as? DetailedTorrentViewController {
                if let cell: MainTableViewCell = sender as? MainTableViewCell {
                    destination.torrentHash = cell.torrentHash
                }
                if let torrentHash = sender as? String {
                    destination.torrentHash = torrentHash
                }
            }

        } else if segue.identifier == "addTorrentSegue" {
            if let destination = segue.destination as? AddTorrentViewController {
                if let userInfo = sender as? [AnyHashable: Any],
                    let torrentURL = userInfo["url"] as? URL,
                    let isFileURL = userInfo["isFileURL"] as? Bool {
                    destination.torrentType = isFileURL ? .file : .magnet
                    destination.torrentURL = torrentURL
                }

                destination.onTorrentAdded = { [weak self] torrentHash in
                    DispatchQueue.main.async {
                        self?.navigationController?.popViewController(animated: true)
                        self?.performSegue(withIdentifier: "detailedTorrentViewSegue", sender: torrentHash)
                    }
                }
            }
        }
    }

}

// MARK: - UISearchResultsUpdating Extension
extension MainTableViewController: UISearchResultsUpdating {

    // MARK: - Private instance methods

    func isFiltering() -> Bool {
        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        return searchController.isActive && (!searchBarIsEmpty() || searchBarScopeIsFiltering)
    }

    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }

    func filterContentForSearchText(_ searchText: String, scope: String = "All") {

        if scope == "Name" {
            filteredTableViewDataSource = tableViewDataSource?.filter {
                return $0.name.lowercased().contains(searchText.lowercased())
                } ?? []
        } else if scope == "Hash" {
            filteredTableViewDataSource = tableViewDataSource?.filter {
                return $0.hash.lowercased().contains(searchText.lowercased())
                } ?? []
        } else if scope == "Tracker" {
            filteredTableViewDataSource = tableViewDataSource?.filter {
                return $0.tracker_host.lowercased().contains(searchText.lowercased())
                } ?? []
        } else {
            filteredTableViewDataSource = tableViewDataSource?.filter {
                return $0.name.lowercased().contains(searchText.lowercased()) ||
                    $0.hash.lowercased().contains(searchText.lowercased()) ||
                    $0.tracker_host.lowercased().contains(searchText.lowercased())
                } ?? []
        }
        // TODO: Sort the Filtered Data
        tableView.reloadData()
    }

    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchController.searchBar.text!, scope: scope)
    }

}

extension MainTableViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        updateSearchResults(for: searchController)
    }
}

extension MainTableViewController: UISearchControllerDelegate {

}

extension Array where Iterator.Element == TableViewTorrent {
    func sort(by sortKey: MainTableViewController.SortKey, ascending: Bool = true) -> [TableViewTorrent] {

        var sortedContent = [TableViewTorrent]()

        switch sortKey {
        case .Name:
            sortedContent = self.sorted {
                $0.name.lowercased() < $1.name.lowercased()
            }
        case .DownloadSpeed:
            sortedContent = self.sorted {
                ($0.download_payload_rate, $0.name.lowercased()) < ($1.download_payload_rate, $1.name.lowercased())
            }
        case .UploadSpeed:
            sortedContent = self.sorted {
                ($0.upload_payload_rate, $0.name.lowercased()) < ($1.upload_payload_rate, $1.name.lowercased())
            }
        case .Size:
            sortedContent = self.sorted {
                ($0.total_size, $0.name.lowercased()) < ($1.total_size, $1.name.lowercased())
            }
        case .Ratio:
            sortedContent = self.sorted {
                ($0.ratio, $0.name.lowercased()) < ($1.ratio, $1.name.lowercased())
            }
        case .TotalDownload:
            sortedContent = self.sorted {
                ($0.all_time_download, $0.name.lowercased()) < ($1.all_time_download, $1.name.lowercased())
            }
        case .TotalUpload:
            sortedContent = self.sorted {
                ($0.total_uploaded, $0.name.lowercased()) < ($1.total_uploaded, $1.name.lowercased())
            }
        case .State:
            sortedContent = self.sorted {
                ($0.state.lowercased(), $0.name.lowercased()) < ($1.state.lowercased(), $1.name.lowercased())
            }
        }

        if !ascending {
            sortedContent.reverse()
        }
        print("Sorted")
        return sortedContent
    }
} // swiftlint:disable:this file_length
