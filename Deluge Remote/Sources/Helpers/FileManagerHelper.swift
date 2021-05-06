//
//  FileManagerHelper.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 6/13/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import Foundation
import Houston

func getDocumentsDirectory() -> URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
}

func getLogFile() -> URL {
    
    let today = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd-yyyy"
    let fileName = "com.rudybermudez.io.DelugeRemote-\(formatter.string(from: today)).log"
    
    let logPath = getDocumentsDirectory().appendingPathComponent("Logs")
    do
    {
        try FileManager.default.createDirectory(atPath: logPath.path, withIntermediateDirectories: true, attributes: nil)
    }
    catch let error as NSError
    {
        Logger.error("Unable to create directory \(error.debugDescription)")
        return getDocumentsDirectory().appendingPathComponent(fileName)
    }
    
    return logPath.appendingPathComponent(fileName)
}
