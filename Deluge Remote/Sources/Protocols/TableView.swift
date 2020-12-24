//
//  TableView.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/23/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit


protocol TableViewCellBuilder: AnyObject {
    func cell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell
}

protocol TableViewSectionProvider {
    var cells: [TableViewCellBuilder] { get set }
    var onRowsAdded: ((_ rows: [Int]) -> ())? { get set }
    var onRowsRemoved: ((_ rows: [Int]) -> ())? { get set }
    
    func rowsCount() -> Int
    func titleForHeader() -> String?
    func updateData()
    func cell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell
    func didSelectRow(in tableView: UITableView, at indexPath: IndexPath) 
}

protocol TableViewModel {
    var sections: [TableViewSection] { get }
    var sectionCount: Int { get }
    func updateModel()
    func rowCount(for section: Int) -> Int
    func sectionHeaderTitle(for section: Int) -> String?
    func cell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell
    func didSelectRow(in tableView: UITableView, at indexPath: IndexPath)
}

class TableViewSection: TableViewSectionProvider {
    
    // Properties
    internal var cells: [TableViewCellBuilder]  = []
    
    public var onRowsAdded: ((_ rows: [Int]) -> ())?
    public var onRowsRemoved: ((_ rows: [Int]) -> ())?
    
    fileprivate var sectionUpdate: (()->())?
    
    init(onSectionUpdate: (()->())? = nil) {
        self.sectionUpdate = onSectionUpdate
    }
    
    func rowsCount() -> Int {
        return cells.count
    }
    
    func titleForHeader() -> String? {
        return nil
    }
    
    func updateData() {}
    
    func cell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row].cell(for: tableView, at: indexPath)
    }
    
    func didSelectRow(in tableView: UITableView, at indexPath: IndexPath) {
    }
    
}
