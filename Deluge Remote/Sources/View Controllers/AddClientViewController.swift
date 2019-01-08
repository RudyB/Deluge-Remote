//
//  ClientCredentialsTableViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 11/16/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import MBProgressHUD
import UIKit

class AddClientViewController: UITableViewController {

    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var hostnameTextField: UITextField!
    @IBOutlet weak var relativePathTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var portTableViewCell: UITableViewCell!
    @IBOutlet weak var networkSecurityControl: UISegmentedControl!

    @IBAction func doneAction(_ sender: UIBarButtonItem) {
        print("Done Action")
        if let onConfigAdded = onConfigAdded, let config = config {
            onConfigAdded(config)
            print("Clicked Closure")
        }
    }

    @IBAction func changeSSL(_ sender: UISegmentedControl) {
        sslEnabled = sender.selectedSegmentIndex == 1
    }

    // swiftlint:disable:next function_body_length
    @IBAction func testConnectionAction(_ sender: Any) {
        var port: String = ""
        var sslConfig: NetworkSecurity!
        sslEnabled = networkSecurityControl.selectedSegmentIndex == 1

        guard
            let nickname = nicknameTextField.text,
            let hostname = hostnameTextField.text,
            let password = passwordTextField.text
            else {
                return
        }
        let relativePath = relativePathTextField.text ?? ""

        port = portTextField.text ?? port
        if sslEnabled {
            sslConfig = NetworkSecurity.https(port: port)
        } else {
            sslConfig = NetworkSecurity.http(port: port)
        }

        if nickname.isEmpty { showAlert(target: self, title: "Nickname cannot be left empty")}
        if hostname.isEmpty { showAlert(target: self, title: "Hostname cannot be empty")}
        if password.isEmpty { showAlert(target: self, title: "Password cannot be empty")}
        if port.isEmpty { showAlert(target: self, title: "Port cannot be empty")}

        if !hostname.isEmpty && !password.isEmpty && !port.isEmpty && !nickname.isEmpty {
            DispatchQueue.main.async {
                MBProgressHUD.showAdded(to: self.view, animated: true)
            }

            let tempConfig = ClientConfig(nickname: nickname, hostname: hostname,
                                          relativePath: relativePath, port: port,
                                          password: password, isHTTP: !self.sslEnabled)

            let tempClient = DelugeClient(config: tempConfig)
            tempClient.authenticate()
                .then { [weak self] isValidScheme -> Void in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view, animated: true)

                        if isValidScheme {
                            self.view.showHUD(title: "Valid Configuration")
                            self.config = tempConfig
                            self.navigationItem.rightBarButtonItem?.isEnabled = true
                        } else {
                            showAlert(target: self, title: "Unable to Authenticate", message: "Invalid Password")
                        }
                    }

                }.catch { [weak self] error in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        if let error = error as? ClientError {
                            showAlert(target: self, title: "Connection failure", message: error.domain())
                        } else {
                            showAlert(target: self, title: "Connection failure", message: error.localizedDescription)
                        }
                    }

            }
        }
    }

    var sslEnabled: Bool = false

    static let storyboardIdentifier = "AddClientVC"

    public var onConfigAdded: ((ClientConfig) -> Void)?

    var config: ClientConfig?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem?.isEnabled = false

        if let config = config {
            self.title = "Edit Client"
            nicknameTextField.text = config.nickname
            hostnameTextField.text = config.hostname
            relativePathTextField.text = config.relativePath
            portTextField.text = config.port
            networkSecurityControl.selectedSegmentIndex = config.isHTTP ? 0 : 1
            passwordTextField.text = config.password
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
}
