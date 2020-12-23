//
//  TorrentConnectedClientCell.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/16/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit

class TorrentPeerTableViewCellData: TVCellBuilder {
    var clientName: String
    var ipAddress: String
    var flag: UIImage?
    var uploadSpeed: String
    var downloadSpeed: String
    var progress: Double
    
    init(clientName: String, ipAddress: String, flag: UIImage, uploadSpeed: String, downloadSpeed: String, progress: Double) {
        self.clientName = clientName
        self.ipAddress = ipAddress
        self.flag = flag
        self.uploadSpeed = uploadSpeed
        self.downloadSpeed = downloadSpeed
        self.progress = progress
    }
    
    init(peer: PeerMetadata) {
        self.clientName = peer.client
        self.ipAddress = peer.ip
        self.flag = UIImage(named: "\(peer.country.lowercased()).png")
        self.uploadSpeed = "↑ \(peer.up_speed.transferRateString())"
        self.downloadSpeed = "\(peer.down_speed.transferRateString()) ↓"
        self.progress = peer.progress
    }
    
    func cell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "torrentPeerTableViewCell", for: indexPath) as! TorrentPeerTableViewCell
        cell.clientName.text = clientName
        cell.flag.image = flag
        cell.ipAddress.text = ipAddress
        cell.uploadSpeed.text = uploadSpeed
        cell.downloadSpeed.text = downloadSpeed
        cell.progress.progress = Float(progress)
        return cell
    }
}

class TorrentPeerTableViewCell: UITableViewCell {
    
    @IBOutlet weak var clientName: UILabel!
    @IBOutlet weak var ipAddress: UILabel!
    @IBOutlet weak var flag: UIImageView!
    @IBOutlet weak var uploadSpeed: UILabel!
    @IBOutlet weak var downloadSpeed: UILabel!
    @IBOutlet weak var progress: UIProgressView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
