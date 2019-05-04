//
//  MainTableViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 11/12/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import Houston
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
        case DateAdded = "Date Added"
    }

    enum Order: String, CaseIterable {
        case Ascending
        case Descending
    }

    // MARK: - Views
    var dataTransferView: UIStackView = {
        let view = UIStackView(frame: CGRect(x: 0, y: 0, width: 170, height: 22))
        view.backgroundColor = UIColor.clear
        return view
    }()

    var currentUploadSpeedLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 11))
        label.font = label.font.withSize(11)
        label.text = "↑ Zero KB/s"
        label.backgroundColor = UIColor.clear
        return label
    }()

    var currentDownloadSpeedLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 11, width: 80, height: 11))
        label.font = label.font.withSize(11)
        label.text = "↓ Zero KB/s"
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

    // MARK: - IBOutlets

    @IBOutlet weak var resumeAllTorrentsBarButton: UIBarButtonItem!
    @IBAction func resumeAllTorrentsAction(_ sender: Any) {
        (isHostOnline == true) ? self.resumeAllTorrents() : ()
    }
    @IBOutlet weak var pauseAllTorrentsBarButton: UIBarButtonItem!
    @IBAction func pauseAllTorrentsAction(_ sender: Any) {
        (isHostOnline == true) ? self.pauseAllTorrents() : ()
    }
    @IBAction func displayOrganizeMenu(_ sender: UIBarButtonItem) {

        let title = "Sorted by: \(activeSortKey.rawValue) (\(activeOrderKey.rawValue))"
        let orderAs = UIAlertAction(title: "Order As", style: .default) { [weak self] _ in
            self?.displayOrderByMenu()
        }
        let sortBy = UIAlertAction(title: "Sort By", style: .default) { [weak self] _ in
            self?.displaySortByMenu()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        showAlert(target: self, title: title, message: nil, style: .actionSheet, actionList: [sortBy, orderAs, cancel])
    }

    // MARK: - Properties

    var activeSortKey = SortKey.Name
    var activeOrderKey = Order.Ascending
    let byteCountFormatter = ByteCountFormatter()
    let searchController = UISearchController(searchResultsController: nil)

    var tableViewDataSource: [TorrentOverview]?
    var filteredTableViewDataSource = [TorrentOverview]()

    var isHostOnline: Bool = false

    var executeNextStepTimer: Timer?

    var shouldRefreshTableView = true
    var allowDelayedExecutionOfNextStep = true

    // MARK: - UI Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Load the user's last sort key and order Key
        if let sortKeyString = UserDefaults.standard.string(forKey: "SortKey"),
            let sortKey = SortKey(rawValue: sortKeyString) {
            self.activeSortKey = sortKey
        }

        if let orderKeyString = UserDefaults.standard.string(forKey: "OrderKey"),
            let orderKey = Order(rawValue: orderKeyString) {
            self.activeOrderKey = orderKey
        }

        self.initUploadDownloadLabels()
        statusHeader.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 22)

        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        self.navigationItem.title = ClientManager.shared.activeClient?.clientConfig.nickname ?? "Deluge Remote"

        self.tableView.accessibilityScroll(UIAccessibilityScrollDirection.down)

        // Setup Notification Center
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNewActiveClient),
                                               name: Notification.Name(ClientManager.NewActiveClientNotification),
                                               object: nil)

        NotificationCenter.default.addObserver(self, selector:
            #selector(self.handleAddTorrentNotification(notification:)),
                                               name: Notification.Name("AddTorrentNotification"), object: nil)
        NewTorrentNotifier.shared.didMainTableVCCreateObserver = true

        // Setup the Search Controller
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
        allowDelayedExecutionOfNextStep = true
        executeNextStep()
    }

    override func viewDidDisappear(_ animated: Bool) {
        allowDelayedExecutionOfNextStep = false
        cancelDelayedExecuteNextStep()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func initUploadDownloadLabels() {
        let currentDataView = UIStackView(frame: CGRect(x: 0, y: 0, width: 80, height: 22))
        currentDataView.axis = .vertical
        currentDataView.addArrangedSubview(currentUploadSpeedLabel)
        currentDataView.addArrangedSubview(currentDownloadSpeedLabel)

        dataTransferView.addArrangedSubview(currentDataView)

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: dataTransferView)
    }

    func updateHeader(with customMsg: String? = nil, isError: Bool = false, color: UIColor? = nil) {
        guard ClientManager.shared.activeClient != nil else {
            statusHeader.text = "No Active Config"
            statusHeader.backgroundColor = UIColor(red: 0.98, green: 0.196, blue: 0.196, alpha: 0.85)
            return
        }

        if let headerText = customMsg {
            self.statusHeader.text = headerText
            if let color = color {
                self.statusHeader.backgroundColor = color
            } else {
                if isError {
                    statusHeader.backgroundColor = UIColor(red: 0.98, green: 0.196, blue: 0.196, alpha: 0.85)
                } else {
                    statusHeader.backgroundColor = UIColor(red: 0.302, green: 0.584, blue: 0.772, alpha: 0.85)
                }
            }

        } else {
            if isHostOnline {
                statusHeader.text = "Host Online"
                statusHeader.backgroundColor = UIColor(red: 0.302, green: 0.584, blue: 0.772, alpha: 0.85)
            } else {
                statusHeader.text =  "Host Offline"
                statusHeader.backgroundColor = UIColor(red: 0.98, green: 0.196, blue: 0.196, alpha: 0.85)
            }
        }
    }

    func reloadTableView() {

        if !shouldRefreshTableView { return }

        DispatchQueue.global(qos: .userInteractive).async {
            self.tableViewDataSource = self.tableViewDataSource?.sort(by: self.activeSortKey, self.activeOrderKey)
            DispatchQueue.main.async {
                Logger.verbose("Updating Table View")
                self.tableView.reloadData()
                if self.isFiltering() {
                    self.updateSearchResults(for: self.searchController)
                }
            }
        }

    }

    func displaySortByMenu() {

        var actions = [UIAlertAction]()

        for item in SortKey.allCases {
            let action = UIAlertAction(title: item.rawValue, style: .default) { [weak self] _ in
                self?.activeSortKey = item
                self?.reloadTableView()
                UserDefaults.standard.set(item.rawValue, forKey: "SortKey")
            }
            actions.append(action)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actions.append(cancel)

        showAlert(target: self, title: "Sort By:", message: nil, style: .actionSheet, actionList: actions)
    }

    func displayOrderByMenu() {

        var actions = [UIAlertAction]()

        for item in Order.allCases {
            let action = UIAlertAction(title: item.rawValue, style: .default) { [weak self] _ in
                self?.activeOrderKey = item
                self?.reloadTableView()
                UserDefaults.standard.set(item.rawValue, forKey: "OrderKey")
            }
            actions.append(action)
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actions.append(cancel)

        showAlert(target: self, title: "Order By:", message: nil,
                  style: .actionSheet, actionList: actions)
    }

    // MARK: - Helper Functions

    @objc func handleAddTorrentNotification(notification: NSNotification) {
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

    func delayedExecuteNextStep() {
        if allowDelayedExecutionOfNextStep {
            if !(executeNextStepTimer?.isValid ?? false) {
                executeNextStepTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
                    self?.executeNextStep()
                }
            } else {
                Logger.warning("Prevented Redundant Delayed Next Step")
            }
        } else {
            Logger.warning("Prevented Request for Delayed Next Step")
        }
    }

    func cancelDelayedExecuteNextStep() {
        Logger.info("Cancelling Delayed Execute of Next Step")
        executeNextStepTimer?.invalidate()
    }

    func executeNextStep() {
        if ClientManager.shared.activeClient == nil { return } // This will keep the timer from restarting

        if !IsConnectedToNetwork() {
            updateHeader(with: "No Active Internet Connection", isError: true, color: UIColor.red)
            delayedExecuteNextStep()
            return
        }

        if isHostOnline {
            downloadNewData()
        } else {
            refreshAuthentication()
        }
    }

    @objc func handleNewActiveClient() {
        Logger.debug("New Client")

        isHostOnline = false
        navigationItem.title = ClientManager.shared.activeClient?.clientConfig.nickname ?? "Deluge Remote"

        // Reset UI
        pauseAllTorrentsBarButton.isEnabled = false
        resumeAllTorrentsBarButton.isEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false
        currentDownloadSpeedLabel.text = "↓ Zero KB/s"
        currentUploadSpeedLabel.text = "↑ Zero KB/s"
        tableViewDataSource?.removeAll()
        reloadTableView()
        updateHeader()

        executeNextStep()
    }

    // MARK: - Deluge UI Wrapper Methods

    func refreshAuthentication () {
        // swiftlint:disable:previous function_body_length

        guard let client = ClientManager.shared.activeClient else { return }
        Logger.info("Began Auth Refresh")

        updateHeader(with: "Attempting Connection",
                     color: UIColor(red: 4.0/255.0, green: 123.0/255.0, blue: 242.0/255.0, alpha: 1.0))

        firstly {
            client.authenticateAndConnect()
        }.then { [weak self] _ -> Void in
            Logger.info("User Authenticated")
            self?.isHostOnline = true

            // Enable UI Components
            self?.navigationItem.rightBarButtonItem?.isEnabled = true
            self?.pauseAllTorrentsBarButton.isEnabled = true
            self?.resumeAllTorrentsBarButton.isEnabled = true

            self?.updateHeader()
            self?.executeNextStep()
        }.catch { [weak self] error in
            self?.isHostOnline = false

            // Disable UI Components
            self?.pauseAllTorrentsBarButton.isEnabled = false
            self?.resumeAllTorrentsBarButton.isEnabled = false
            self?.navigationItem.rightBarButtonItem?.isEnabled = false

            self?.currentDownloadSpeedLabel.text = "↓ Zero KB/s"
            self?.currentUploadSpeedLabel.text = "↑ Zero KB/s"

            self?.tableViewDataSource?.removeAll()
            self?.reloadTableView()

            self?.delayedExecuteNextStep() // Queue delayed exec. of next step

            var errorMsg = ""
            if let error = error as? ClientError {
                switch error {
                case .incorrectPassword:
                    errorMsg = "Incorrect Password"
                    self?.cancelDelayedExecuteNextStep() // No Point for the next step to process
                case .noHostsExist:
                    errorMsg = "No Hosts Configured for WebUI"
                case .hostNotOnline:
                    errorMsg = "Default Daemon for WebUI Offline"
                default:
                    errorMsg = "Host Offline"
                }
                Logger.error(error.domain())
            } else {
                Logger.error(error)
                errorMsg = error.localizedDescription
            }

            self?.updateHeader(with: errorMsg, isError: true)
        }
    }

    func downloadNewData() {

        guard let client = ClientManager.shared.activeClient else { return }
        Logger.verbose("Attempting to get all torrents")

        firstly {
            client.getAllTorrents()
        }.then { [weak self] data -> Void in
            self?.tableViewDataSource = data
            self?.reloadTableView()
        }.then {
              client.getSessionStatus()
        }.then { [weak self] status -> Void in
            self?.currentDownloadSpeedLabel.text = "↓ \(status.payload_download_rate.transferRateString())"
            self?.currentUploadSpeedLabel.text = "↑ \(status.payload_upload_rate.transferRateString())"
        }.then { [weak self] _ -> Void in
            self?.updateHeader()
            self?.delayedExecuteNextStep()
        }.catch { [weak self] error in
            guard let self = self else { return }

            self.isHostOnline = false

            // Disable UI Components
            self.pauseAllTorrentsBarButton.isEnabled = false
            self.resumeAllTorrentsBarButton.isEnabled = false
            self.navigationItem.rightBarButtonItem?.isEnabled = false

            self.currentDownloadSpeedLabel.text = "↓ Zero KB/s"
            self.currentUploadSpeedLabel.text = "↑ Zero KB/s"

            self.tableViewDataSource?.removeAll()
            self.reloadTableView()

            self.updateHeader()

            if let error = error as? ClientError {
                Logger.error(error.domain())
                showAlert(target: self, title: "Error", message: error.domain())
            } else {
                Logger.error(error)
                showAlert(target: self, title: "Error", message: error.localizedDescription)
            }

            self.executeNextStep() // Immediately execute the next step
        }
    }

    func pauseAllTorrents() {
        ClientManager.shared.activeClient?.pauseAllTorrents { [weak self] result in
            guard let self = self else { return }
            var haptic: UINotificationFeedbackGenerator?  = UINotificationFeedbackGenerator()
            haptic?.prepare()
            switch result {
            case .success:
                DispatchQueue.main.async {
                    haptic?.notificationOccurred(.success)
                    self.view.showHUD(title: "Successfully Paused")
                }
                Logger.verbose("All Torrents Paused Successfully")
            case .failure(let error):
                DispatchQueue.main.async {
                    haptic?.notificationOccurred(.error)
                    self.view.showHUD(title: "Failed to Pause All Torrents", type: .failure)
                }
                Logger.error(error)
            }
        }
    }

    func resumeAllTorrents() {
        ClientManager.shared.activeClient?.resumeAllTorrents { [weak self] result in
            guard let self = self else { return }
            var haptic: UINotificationFeedbackGenerator? = UINotificationFeedbackGenerator()
            haptic?.prepare()
            switch result {
            case .success:
                DispatchQueue.main.async {
                    haptic?.notificationOccurred(.success)
                    self.view.showHUD(title: "Successfully Resumed")
                }
                Logger.verbose("All Torrents Resumed")
            case .failure(let error):
                DispatchQueue.main.async {
                    haptic?.notificationOccurred(.error)
                    self.view.showHUD(title: "Failed to Resume All Torrents", type: .failure)
                }
                Logger.error(error)
            }
            haptic = nil
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
        return self.statusHeader
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableViewDataSource = tableViewDataSource else {
            return 0
        }

        if isFiltering() {
            return filteredTableViewDataSource.count
        } else {
            return tableViewDataSource.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let tableViewDataSource = tableViewDataSource,
            let cell = tableView.dequeueReusableCell(withIdentifier: "mainTableViewCell", for: indexPath)
                as? MainTableViewCell
            else {
                return tableView.dequeueReusableCell(withIdentifier: "mainTableViewCell", for: indexPath)
        }

        let currentItem: TorrentOverview
        if isFiltering() {
            currentItem = filteredTableViewDataSource[indexPath.row]
        } else {
            currentItem = tableViewDataSource[indexPath.row]
        }

        cell.nameLabel.text = currentItem.name
        cell.progressBar.setProgress(Float(currentItem.progress/100), animated: false)
        cell.currentStatusLabel.text = currentItem.state
        if currentItem.state == "Error" {
            cell.currentStatusLabel.textColor = UIColor.red
        } else {
            cell.currentStatusLabel.textColor = UIColor.black
        }
        cell.downloadSpeedLabel.text =
        "\(byteCountFormatter.string(fromByteCount: Int64(currentItem.download_payload_rate))) ↓"
        cell.uploadSpeedLabel.text =
        "↑ \(byteCountFormatter.string(fromByteCount: Int64(currentItem.upload_payload_rate)))"
        cell.torrentHash = currentItem.hash
        if currentItem.eta == 0 {
            cell.etaLabel.text = "\(currentItem.ratio.roundTo(places: 3))"
        } else {
            cell.etaLabel.text = currentItem.eta.timeRemainingString(unitStyle: .abbreviated)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        shouldRefreshTableView = false
    }
    override func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        shouldRefreshTableView = true
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // swiftlint:disable:next line_length
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            // handle delete (by removing the data from your array and updating the tableview)
            if let cell = tableView.cellForRow(at: indexPath) as? MainTableViewCell {

                let deleteTorrent = UIAlertAction(title: "Delete Torrent", style: .default) { [weak self] _ in

                    ClientManager.shared.activeClient?.removeTorrent(withHash: cell.torrentHash, removeData: false)
                        .then { [weak self] _ -> Void in
                            guard let self = self else { return }
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
                            self.view.showHUD(title: "Torrent Successfully Deleted")
                        }
                        .catch { [weak self] error in
                            self?.view.showHUD(title: "Failed to Delete Torrent", type: .failure)
                        }

                    }

                let deleteTorrentWithData = UIAlertAction(title: "Delete Torrent with Data", style: .default) { [weak self] _ in

                    ClientManager.shared.activeClient?.removeTorrent(withHash: cell.torrentHash, removeData: false)
                        .then { [weak self] _ -> Void in
                            guard let self = self else { return }
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
                            self.view.showHUD(title: "Torrent Successfully Deleted")
                        }
                        .catch { [weak self] error in
                            self?.view.showHUD(title: "Failed to Delete Torrent", type: .failure)
                    }
                }

                let cancel = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                    self?.tableView.setEditing(false, animated: true)
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
                return $0.name.parsedTorrentName().contains(searchText.parsedTorrentName())
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
                return $0.name.parsedTorrentName().contains(searchText.parsedTorrentName()) ||
                    $0.hash.lowercased().contains(searchText.lowercased()) ||
                    $0.tracker_host.lowercased().contains(searchText.lowercased())
                } ?? []
        }
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

// MARK: - Extension for sorting torrents
extension Array where Iterator.Element == TorrentOverview {
    func sort(by sortKey: MainTableViewController.SortKey,
              _ order: MainTableViewController.Order = .Ascending) -> [TorrentOverview] {

        var sortedContent = [TorrentOverview]()

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
        case .DateAdded:
            sortedContent = self.sorted {
                ($0.time_added, $0.name.lowercased()) < ($1.time_added, $1.name.lowercased())
            }
        }

        if order == .Descending {
            sortedContent.reverse()
        }
        Logger.verbose("Sorted")
        return sortedContent
    }
} // swiftlint:disable:this file_length
