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

protocol MainTableViewControllerDelegate: AnyObject {
    func torrentSelected(torrentHash: String)
    func removeTorrent(with hash: String, removeData: Bool, onCompletion: ((_ onServerComplete: APIResult<Void>, _ onClientComplete: @escaping ()->())->())?)
    func showAddTorrentView()
    func showSettingsView()
}

class MainTableViewController: UITableViewController, Storyboarded {
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
        label.autoresizingMask = UIView.AutoresizingMask.flexibleLeftMargin
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
    @IBAction func addTorrentAction(_ sender: Any) {
        guard let delegate = delegate else { return }
        delegate.showAddTorrentView()
    }
    
    @IBAction func showSettingsAction(_ sender: Any) {
        guard let delegate = delegate else { return }
        delegate.showSettingsView()
    }
    
    lazy var slideInTransitioningDelegate = SlideInPresentationManager()
    @IBOutlet weak var organizeMenuBarButton: UIBarButtonItem!
    @IBAction func displayOrganizeMenu(_ sender: UIBarButtonItem) {

        let vc: TorrentSortingPopup = TorrentSortingPopup.instantiate()
        vc.sortKey = activeSortKey
        vc.orderKey = activeOrderKey
        vc.onApplied = { [weak self] (sortKey, orderKey) in
            self?.activeSortKey = sortKey
            self?.activeOrderKey = orderKey
        }
        vc.transitioningDelegate = slideInTransitioningDelegate
        vc.modalPresentationStyle = .custom
        present(vc, animated: true, completion: nil)
        
    }
    
    // MARK: - Properties

    let hapticEngine = UINotificationFeedbackGenerator()
    weak var delegate: MainTableViewControllerDelegate?
    
    var collapseDetailViewController: Bool = true

    var activeSortKey = SortKey.Name {
        didSet {
            reloadTableView()
            UserDefaults.standard.set(activeSortKey.rawValue, forKey: "SortKey")
        }
    }
    
    var activeOrderKey = Order.Ascending {
        didSet {
            reloadTableView()
            UserDefaults.standard.set(activeOrderKey.rawValue, forKey: "OrderKey")
        }
    }
    
    let byteCountFormatter = ByteCountFormatter()
    let searchController = UISearchController(searchResultsController: nil)

    var tableViewDataSource: [TorrentOverview]?
    var filteredTableViewDataSource = [TorrentOverview]()
    var selectedHash: String?
    var animateToSelectedHash = false

    var isHostOnline: Bool = false
    var shouldRefreshTableView = true

    
    var pollingTimer: RepeatingTimer? // FYI: Need to set to nil to avoid a memory leak
    var pollingQueue: DispatchQueue?

    // MARK: - UI Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pollingQueue = DispatchQueue(label: "io.rudybermudez.deluge-remote.MainTableView.PollingQueue", qos: .userInteractive)
        pollingTimer = RepeatingTimer(timeInterval: .seconds(5), leeway: .seconds(1), queue: pollingQueue)
        pollingTimer?.eventHandler = dataPollingEvent

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
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter Torrents"
        navigationItem.searchController = searchController
        self.definesPresentationContext = true

        // Setup the Scope Bar
        searchController.searchBar.scopeButtonTitles = ["All", "Name", "Hash", "Tracker"]
        searchController.searchBar.delegate = self

        self.tableView.rowHeight = 60
        
        forceDataPollingUpdate()
        pollingTimer?.resume()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.initUploadDownloadLabels()
        title = ClientManager.shared.activeClient?.clientConfig.nickname ?? "Deluge Remote"
        hidesBottomBarWhenPushed = false
        navigationController?.setToolbarHidden(false, animated: true)
        
        navigationController?.title = title
        splitViewController?.title = title
        if let svc = splitViewController {
            if svc.isCollapsed {
                selectedHash = nil
                if let selectionIndexPath = tableView.indexPathForSelectedRow {
                    tableView.deselectRow(at: selectionIndexPath, animated: false)
                }
            } else{
                forceDataPollingUpdate()
                restoreSelectedRow()
            }
        }
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

                self.restoreSelectedRow()
            }
        }
    }

    // MARK: - Data Polling
    
    /// Event Handler for RepeatingTimer
    func dataPollingEvent()
    {
        guard (ClientManager.shared.activeClient != nil) else { return }
        
        if !IsConnectedToNetwork() {
            DispatchQueue.main.async {
                self.updateHeader(with: "No Active Internet Connection", isError: true, color: UIColor.red)
            }
            return
        }
        
        if isHostOnline {
            downloadNewData()
        } else {
            refreshAuthentication()
        }
    }
    
    func forceDataPollingUpdate() {
        pollingQueue?.async { [weak self] in self?.dataPollingEvent() }
    }
    
    // MARK: - Helper Functions
    
    fileprivate func deletedTorrentCallbackHandler(indexPath: IndexPath, result: APIResult<Void>, onGuiUpdatesComplete: ()->())
    {
        switch result {
        case .success():
            if isFiltering() {
                tableViewDataSource?.removeAll { $0 == self.filteredTableViewDataSource[indexPath.row] }
                self.filteredTableViewDataSource.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            } else {
                tableViewDataSource?.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            tableView.setEditing(false, animated: true)
            view.showHUD(title: "Torrent Successfully Deleted")
            onGuiUpdatesComplete()
        case .failure(_):
            view.showHUD(title: "Failed to Delete Torrent", type: .failure)
            onGuiUpdatesComplete()
        }
    }

    public func restoreSelectedRow() {
        guard let selectedHash = selectedHash else { return }
        if isFiltering() {
            filteredTableViewDataSource.enumerated().forEach {
                if $1.hash == selectedHash && !splitViewController!.isCollapsed {
                    tableView.selectRow(
                        at: IndexPath(row: $0, section: 0),
                        animated: animateToSelectedHash,
                        scrollPosition: animateToSelectedHash ? .top : .none)
                    return
                }
            }
        } else {
            tableViewDataSource?.enumerated().forEach {
                if $1.hash == selectedHash && !splitViewController!.isCollapsed {
                    tableView.selectRow(
                        at: IndexPath(row: $0, section: 0),
                        animated: animateToSelectedHash,
                        scrollPosition: animateToSelectedHash ? .top : .none)
                    return
                }
            }
        }
        animateToSelectedHash = false
    }

    @objc func handleNewActiveClient() {
        Logger.debug("New Client")

        isHostOnline = false
        title = ClientManager.shared.activeClient?.clientConfig.nickname ?? "Deluge Remote"
        navigationController?.title = title
        splitViewController?.title = title

        // Reset UI
        pauseAllTorrentsBarButton.isEnabled = false
        resumeAllTorrentsBarButton.isEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false
        currentDownloadSpeedLabel.text = "↓ Zero KB/s"
        currentUploadSpeedLabel.text = "↑ Zero KB/s"
        tableViewDataSource?.removeAll()
        reloadTableView()
        updateHeader()
    }
    
    @objc func handleOrientationChange()
      {
        self.initUploadDownloadLabels()
      }

    // MARK: - Deluge UI Wrapper Methods

    func refreshAuthentication () {
        // swiftlint:disable:previous function_body_length

        guard let client = ClientManager.shared.activeClient else { return }
        Logger.debug("Began Auth Refresh")

        DispatchQueue.main.async { [weak self] in
            self?.updateHeader(with: "Attempting Connection",
                         color: UIColor(red: 4.0/255.0, green: 123.0/255.0, blue: 242.0/255.0, alpha: 1.0))
        }

        firstly {
            client.authenticateAndConnect()
        }.done { [weak self] _ in
            Logger.debug("User Authenticated")
            self?.isHostOnline = true

            // Enable UI Components
            self?.navigationItem.rightBarButtonItem?.isEnabled = true
            self?.pauseAllTorrentsBarButton.isEnabled = true
            self?.resumeAllTorrentsBarButton.isEnabled = true
            self?.updateHeader()
            self?.pollingQueue?.async { [weak self] in self?.dataPollingEvent() }
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

            var errorMsg = ""
            if let error = error as? ClientError {
                switch error {
                case .incorrectPassword:
                    errorMsg = "Incorrect Password"
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
        }.done { [weak self] data -> Void in
            self?.tableViewDataSource = data
            self?.reloadTableView()
        }.then { _ in
            client.getSessionStatus()
        }.done { [weak self] status in

            let download  = status.payload_download_rate.transferRateString()
            let upload = status.payload_upload_rate.transferRateString()

            self?.currentDownloadSpeedLabel.text = "↓ \(download)"
            self?.currentUploadSpeedLabel.text = "↑ \(upload)"
        }.done { [weak self] _ in
            self?.updateHeader()
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
            }
        }
    }

    func pauseAllTorrents() {
        ClientManager.shared.activeClient?.pauseAllTorrents { [weak self] result in
            guard let self = self else { return }
            let haptic: UINotificationFeedbackGenerator?  = UINotificationFeedbackGenerator()
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

        cell.paused = currentItem.paused
        cell.nameLabel.text = currentItem.name
        cell.progressBar.setProgress(Float(currentItem.progress/100), animated: false)
        cell.currentStatusLabel.text = currentItem.state
        if currentItem.state == "Error" {
            cell.currentStatusLabel.textColor = UIColor.red
        } else {
            cell.currentStatusLabel.textColor = ColorCompatibility.label
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
        collapseDetailViewController = false

        if let selectedCell = tableView.cellForRow(at: indexPath) as? MainTableViewCell {
            selectedHash = selectedCell.torrentHash
            if let delegate = delegate
            {
                delegate.torrentSelected(torrentHash: selectedCell.torrentHash)
            }
            
        }
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
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? MainTableViewCell else { return }
        
        if editingStyle == UITableViewCell.EditingStyle.delete {
            // handle delete (by removing the data from your array and updating the tableview)
            
            let deleteTorrent = UIAlertAction(title: "Delete Torrent", style: .default) { [weak self] _ in
                self?.delegate?.removeTorrent(with: cell.torrentHash, removeData: false) { [weak self] result, onClientComplete  in
                    self?.deletedTorrentCallbackHandler(indexPath: indexPath, result: result, onGuiUpdatesComplete: onClientComplete)
                }
            }
            
            let deleteTorrentWithData = UIAlertAction(title: "Delete Torrent with Data", style: .default) { [weak self] _ in
                self?.delegate?.removeTorrent(with: cell.torrentHash, removeData: true) { [weak self] result, onClientComplete in
                    self?.deletedTorrentCallbackHandler(indexPath: indexPath, result: result, onGuiUpdatesComplete: onClientComplete)
                }
            }
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                self?.tableView.setEditing(false, animated: true)
            }

            showAlert(target: self, title: "Remove the selected Torrent?",
                      style: .alert, actionList: [deleteTorrent, deleteTorrentWithData, cancel])
        }
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        // Get the actual cell instance for the index path
        guard let cell = tableView.cellForRow(at: indexPath) as? MainTableViewCell else { return nil }
        
        // Instantiate the detail view controller
        let vc  = TorrentDetailViewTabController.instantiate()
        vc.torrentHash = cell.torrentHash
        
        var actionList: [UIMenuElement] = []
        
        if cell.paused {
            let resume = UIAction( title: "Resume", image: UIImage(systemName: "play.fill")) { [weak self] _ in
                ClientManager.shared.activeClient?.resumeTorrent(withHash: cell.torrentHash) { (result) in
                    DispatchQueue.main.async {
                        self?.playPauseActionHandler(paused: cell.paused, with: result)
                    }
                }
            }
            actionList.append(resume)
        } else {
            let pause = UIAction(title: "Pause", image: UIImage(systemName: "pause")) { [weak self] _ in
                ClientManager.shared.activeClient?.pauseTorrent(withHash: cell.torrentHash){ (result) in
                    DispatchQueue.main.async {
                        self?.playPauseActionHandler(paused: cell.paused, with: result)
                    }
                }
            }
            actionList.append(pause)
        }
        
        let delete = UIAction(title: "Delete Torrent", attributes: [.destructive]) { [weak self] _ in
            self?.delegate?.removeTorrent(with: cell.torrentHash, removeData: false) { [weak self] result, onClientComplete  in
                self?.deletedTorrentCallbackHandler(indexPath: indexPath, result: result, onGuiUpdatesComplete: onClientComplete)
            }
        }
        
        let deleteWithData = UIAction(title: "Delete Torrent with Data", attributes: [.destructive]) { [weak self] _ in
            self?.delegate?.removeTorrent(with: cell.torrentHash, removeData: true) { [weak self] result, onClientComplete in
                self?.deletedTorrentCallbackHandler(indexPath: indexPath, result: result, onGuiUpdatesComplete: onClientComplete)
            }
        }
        
        let deleteMenu = UIMenu(title: "Delete", image: UIImage(systemName: "trash.fill"), options: [.destructive], children: [delete, deleteWithData])
        actionList.append(deleteMenu)

        let menu = UIMenu(title: "Actions", children: actionList)
        
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: { vc }, actionProvider: { _ in menu })
    }
    
    override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        
        guard
            let indexPath = configuration.identifier as? IndexPath,
            let cell = tableView.cellForRow(at: indexPath) as? MainTableViewCell
        else { return }
        
        selectedHash = cell.torrentHash
        delegate?.torrentSelected(torrentHash: cell.torrentHash)
    }
    
    fileprivate func playPauseActionHandler(paused: Bool, with result: APIResult<Void>) {
        
        switch result {
           case .success:
               hapticEngine.notificationOccurred(.success)
               
               if paused {
                    view.showHUD(title: "Successfully Resumed Torrent")
               } else {
                    view.showHUD(title: "Successfully Paused Torrent")
               }

           case .failure:
               hapticEngine.notificationOccurred(.error)
               
               if paused {
                   view.showHUD(title: "Failed To Resume Torrent", type: .failure)
               } else {
                   view.showHUD(title: "Failed to Pause Torrent", type: .failure)
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
        restoreSelectedRow()
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
}
// swiftlint:disable:this file_length
