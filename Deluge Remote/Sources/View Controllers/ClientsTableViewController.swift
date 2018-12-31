//
//  ClientsTableViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/18/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import UIKit
import Valet

class ClientsTableViewController: UITableViewController {

    var configs = [ClientConfig]()

    private let keychain = Valet.valet(with: Identifier(nonEmpty: "io.rudybermudez.deluge")!,
                                       accessibility: .whenUnlocked)

    @IBAction func AddClientAction(_ sender: UIBarButtonItem) {
        showAddClientVC()
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        if let configData = keychain.object(forKey: "ClientConfigs") {
            let decoder = JSONDecoder()
            if let configs = try? decoder.decode([ClientConfig].self, from: configData) {
                self.configs = configs
                tableView.reloadData()
            }
        }

        if configs.isEmpty {
           showAddClientVC()

        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if configs.isEmpty {
            keychain.removeObject(forKey: "ClientConfigs")
        } else {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(configs) {
                keychain.set(object: encoded, forKey: "ClientConfigs")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func showAddClientVC() {
        let vc = storyboard?.instantiateViewController(withIdentifier: AddClientViewController.storyboardIdentifier)
            as! AddClientViewController // swiftlint:disable:this force_cast

        vc.onConfigAdded = { [weak self] config in
            if self?.configs.isEmpty ?? false {
                self?.tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.accessoryType = .checkmark
                ClientManager.shared.activeClient = DelugeClient(config: config)
            }
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

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // swiftlint:disable:next line_length
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { action, index in
            let vc = self.storyboard?.instantiateViewController(withIdentifier:
                AddClientViewController.storyboardIdentifier)
                as! AddClientViewController // swiftlint:disable:this force_cast
            vc.config = self.configs[index.row]

            if vc.config == ClientManager.shared.activeClient?.config {
                vc.onConfigAdded = { [weak self] config in
                    self?.configs[index.row] = config
                    ClientManager.shared.activeClient = DelugeClient(config: config)
                    self?.navigationController?.popViewController(animated: true)
                }
            } else {
                vc.onConfigAdded = { [weak self] config in
                    self?.configs[index.row] = config
                    self?.navigationController?.popViewController(animated: true)
                }
            }
            self.navigationController?.pushViewController(vc, animated: true)
            print("Edit button tapped")
        }
        edit.backgroundColor = .orange

        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
            print("Delete button tapped")

            ClientManager.shared.activeClient = nil
            self.configs.remove(at: index.row)
            tableView.deleteRows(at: [index], with: .automatic)
        }
        delete.backgroundColor = .red

        return [delete, edit]
    }
}
