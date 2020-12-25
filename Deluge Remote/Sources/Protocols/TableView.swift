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
    func registerCell( in tableView: UITableView)
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
    func registerCells(in tableView: UITableView)
}

class TableViewModel {
    internal var sections: [TableViewSection] = []
    
    public var sectionCount: Int  {
        return sections.count
    }
    
    func registerCells(in tableView: UITableView) {
        sections.forEach { $0.registerCells(in: tableView) }
    }
    
    func updateModel() {}
    
    func rowCount(for section: Int) -> Int {
        if section > sectionCount {
            return 0
        } else {
            return sections[section].rowsCount()
        }
    }
    
    func sectionHeaderTitle(for section: Int) -> String? {
        if section > sectionCount {
            return nil
        } else {
            return sections[section].titleForHeader()
        }
    }
    
    func cell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        return sections[indexPath.section].cell(for: tableView, at: indexPath)
    }
    
    func didSelectRow(in tableView: UITableView, at indexPath: IndexPath) {
        sections[indexPath.section].didSelectRow(in: tableView, at: indexPath)
    }
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
    
    func registerCells(in tableView: UITableView) {
        for cell in cells {
            cell.registerCell(in: tableView)
        }
    }
}
