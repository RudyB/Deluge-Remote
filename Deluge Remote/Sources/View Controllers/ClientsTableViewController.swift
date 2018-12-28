//
//  ClientsTableViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/18/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import UIKit

class ClientsTableViewController: UITableViewController {

    var configs = [ClientConfig]()

    @IBAction func AddClientAction(_ sender: UIBarButtonItem) {
        showAddClientVC()
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        if let ConfigData = UserDefaults.standard.object(forKey: "ClientConfigs") as? Data {
            let decoder = JSONDecoder()
            if let configs = try? decoder.decode([ClientConfig].self, from: ConfigData) {
                self.configs = configs
                tableView.reloadData()
            }
        }

        if configs.isEmpty {
           showAddClientVC()

        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(configs) {
            UserDefaults.standard.set(encoded, forKey: "ClientConfigs")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func showAddClientVC() {
        let vc = storyboard?.instantiateViewController(withIdentifier: AddClientViewController.storyboardIdentifier) as! AddClientViewController
        vc.onConfigAdded = { [weak self] (config) in
            self?.configs.append(config)
            self?.navigationController?.popViewController(animated: true)
            self?.tableView.reloadData()

        }
        navigationController?.pushViewController(vc, animated: true)
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return configs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = configs[indexPath.row].nickname
        cell.selectionStyle = .none
        cell.accessoryType = .none
        if let client = ClientManager.shared.activeClient {
            if  client.config == configs[indexPath.row] {
                cell.accessoryType = .checkmark
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        ClientManager.shared.activeClient = DelugeClient(config: configs[indexPath.row])
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
}
