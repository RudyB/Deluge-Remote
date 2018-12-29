//
//  ClientCredentialsTableViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 11/16/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

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
		if (sender.selectedSegmentIndex == 0) { sslEnabled = false } else { sslEnabled = true }
		portTableViewCell.isHidden = sslEnabled
		tableView.beginUpdates()
		tableView.endUpdates()
	}

	@IBAction func testConnectionAction(_ sender: Any) {
		var port: String = ""
		var sslConfig: NetworkSecurity!

		guard
            let nickname = nicknameTextField.text,
            let hostname = hostnameTextField.text,
            let password = passwordTextField.text
        else {
			return
		}
		let relativePath = relativePathTextField.text ?? ""

		if sslEnabled {
			port = "443"
			sslConfig = NetworkSecurity.https
		} else {
			port = portTextField.text ?? port
			sslConfig = NetworkSecurity.http(port: port)
		}

		// FIXME: If both fields are empty then 2 alerts
        if nickname.isEmpty { showAlert(target: self, title: "Nickname cannot be left empty")}
		if hostname.isEmpty { showAlert(target: self, title: "Hostname cannot be empty")}
		if password.isEmpty { showAlert(target: self, title: "Password cannot be empty")}
		if port.isEmpty { showAlert(target: self, title: "Port cannot be empty")}

		if !hostname.isEmpty && !password.isEmpty && !port.isEmpty && !nickname.isEmpty {
			let url = buildURL(hostname: hostname, relativePath: relativePath, sslConfig: sslConfig)
			DelugeClient.validateCredentials(url: url, password: password).then { (isValidScheme) -> Void in
				if isValidScheme {
					showAlert(target: self, title: "Connection successful")
                    self.config = ClientConfig(nickname: nickname, hostname: hostname, relativePath: relativePath, port: port, password: password, isHTTP: !self.sslEnabled)
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
				} else {
					showAlert(target: self, title: "Unable to Authenticate", message: "Invalid Password")
				}
			}.catch(execute: { (error) in
				if let error = error as? ClientError {
					showAlert(target: self, title: "Connection failure", message: error.domain())
				} else {
					showAlert(target: self, title: "Connection failure", message: error.localizedDescription)
				}

			})
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

	func buildURL(hostname: String, relativePath: String?, sslConfig: NetworkSecurity) -> String {
		var host = hostname.replacingOccurrences(of: "http://", with: "")
		host = host.replacingOccurrences(of: "https://", with: "")
		let path = relativePath ?? ""
		return "\(sslConfig.name())\(host):\(sslConfig.port())\(path)/json"
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let cell = super.tableView(tableView, cellForRowAt: indexPath)
		if cell == portTableViewCell {
			switch sslEnabled {
			case true: return 0
			case false: return 44
			}
		} else {
			return super.tableView(tableView, heightForRowAt: indexPath)
		}
	}
}
