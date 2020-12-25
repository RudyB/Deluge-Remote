//
//  TorrentSortingPopup.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/23/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit

class TorrentSortingPopup: UIViewController, Storyboarded {
    
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func orderSelected(_ sender: Any) {
        orderKey = MainTableViewController.Order.allCases[segmentedControl.selectedSegmentIndex]
    }
    @IBAction func onApply(_ sender: Any) {
        if let onApplied = onApplied {
            onApplied(sortKey, orderKey)
        }
        dismiss(animated: true, completion: nil)
    }
    
    var onApplied: ((MainTableViewController.SortKey, MainTableViewController.Order)->())?
    
    var sortKey: MainTableViewController.SortKey = .Name
    var orderKey: MainTableViewController.Order = .Ascending
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        picker.dataSource = self
        picker.delegate = self
        
        if let sortKeyIndex = MainTableViewController.SortKey.allCases.firstIndex(of: sortKey) {
                picker.selectRow(sortKeyIndex, inComponent: 0, animated: false)
        }
        if let orderKeyIndex = MainTableViewController.Order.allCases.firstIndex(of: orderKey) {
            segmentedControl.selectedSegmentIndex = orderKeyIndex
        }
        
        view.layer.cornerRadius = 5;
        view.layer.masksToBounds = true;
    }
    
    
}

extension TorrentSortingPopup: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return MainTableViewController.SortKey.allCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return MainTableViewController.SortKey.allCases[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        sortKey = MainTableViewController.SortKey.allCases[row]
    }
}
