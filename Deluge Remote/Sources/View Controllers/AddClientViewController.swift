//
//  ClientCredentialsTableViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 11/16/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import Houston
import MBProgressHUD
import UIKit

class AddClientViewController: UITableViewController, Storyboarded {

    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var hostnameTextField: UITextField!
    @IBOutlet weak var relativePathTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var portTableViewCell: UITableViewCell!
    @IBOutlet weak var networkSecurityControl: UISegmentedControl!

    @IBAction func doneAction(_ sender: UIBarButtonItem) {
        if let onConfigAdded = onConfigAdded, let config = config {
            onConfigAdded(config)
        }
    }

    @IBAction func changeSSL(_ sender: UISegmentedControl) {
        sslEnabled = sender.selectedSegmentIndex == 1
    }

    @IBAction func testConnectionAction(_ sender: Any) {
        
        sslEnabled = networkSecurityControl.selectedSegmentIndex == 1
        
        guard
            let nickname = nicknameTextField.text,
            let hostname = hostnameTextField.text,
            let password = passwordTextField.text,
            let portString = portTextField.text,
            let relativePath = relativePathTextField.text
        else { return }
        
        if nickname.isEmpty { showAlert(target: self, title: "Nickname cannot be left empty")}
        if hostname.isEmpty { showAlert(target: self, title: "Hostname cannot be empty")}
        if portString.isEmpty { showAlert(target: self, title: "Port cannot be empty")}
        
        guard let port = Int(portString) else {
            showAlert(target: self, title: "Port must be a numeric type")
            return
        }
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        guard let tempConfig = ClientConfig(nickname: nickname, hostname: hostname,
                                            relativePath: relativePath, port: port,
                                            password: password, isHTTP: !sslEnabled)
        else {
            MBProgressHUD.hide(for: self.view, animated: true)
            showAlert(target: self, title: "Invalid Config", message: "Unable to parse a valid URL from the config")
            return
        }
        
        tempClient = DelugeClient(config: tempConfig)
        tempClient?.authenticateAndConnect()
            .done { [weak self] in
                guard let self = self else { return }
                MBProgressHUD.hide(for: self.view, animated: true)
                self.view.showHUD(title: "Valid Configuration")
                self.config = tempConfig
            }.catch { [weak self] error in
                guard let self = self else { return }
                MBProgressHUD.hide(for: self.view, animated: true)
                if let error = error as? ClientError {
                    Logger.error(error)
                    showAlert(target: self, title: "Connection failure", message: error.localizedDescription)
                } else {
                    Logger.error(error)
                    showAlert(target: self, title: "Connection failure", message: error.localizedDescription)
                }
            }
    }

    var sslEnabled: Bool = false

    static let storyboardIdentifier = "AddClientVC"

    public var onConfigAdded: ((ClientConfig) -> Void)?

    var config: ClientConfig? {
        didSet {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    var tempClient: DelugeClient?

    deinit {
        Logger.debug("Destroyed")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem?.isEnabled = config != nil

        if let config = config {
            self.title = "Edit Client"
            nicknameTextField.text = config.nickname
            hostnameTextField.text = config.hostname
            relativePathTextField.text = config.relativePath
            portTextField.text = "\(config.port)"
            networkSecurityControl.selectedSegmentIndex = config.isHTTP ? 0 : 1
            passwordTextField.text = config.password
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case 0: return 1
            case 1: return 5
            case 2: return 1
            default: return 0
        }
    }
}
