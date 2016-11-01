//
//  ListViewController.swift
//  tracker
//
//  Created by Griffin Schneider on 11/1/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import DRYUI

class ListViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    private let completion: () -> Void
    fileprivate let tableView: UITableView
    fileprivate let dateFormatter: DateFormatter = {
        let t = DateFormatter()
        t.dateStyle = .medium
        t.timeStyle = .medium
        return t
    }()
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    init(completion: @escaping () -> Void) {
        
        
        self.completion = completion
        self.tableView = UITableView()
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
        
        view.addSubview(tableView) { v, make in
            v.delegate = self
            v.dataSource = self
            v.backgroundColor = UIColor.flatNavyBlueColorDark()
            make.edges.equalTo(v.superview!)
        }
    }
    
    fileprivate func eventIndex(forRow row: Int) -> Int {
        return SSyncManager.data.value.events.count - row - 1
    }
    
    fileprivate func event(forRow row: Int) -> SEvent {
        return SSyncManager.data.value.events[eventIndex(forRow: row)]
    }
    
    @objc private func doneButtonPressed() {
        completion()
    }
}

extension ListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SSyncManager.data.value.events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        }
        cell?.backgroundColor = UIColor.flatNavyBlueColorDark()
        cell?.textLabel?.textColor = UIColor.flatWhiteColorDark()
        cell?.textLabel?.highlightedTextColor = UIColor.flatGray()
        cell?.detailTextLabel?.textColor = UIColor.flatWhiteColorDark()
        cell?.detailTextLabel?.highlightedTextColor = UIColor.flatGray()
        
        let e = event(forRow: indexPath.row)
        
        let icon = SSyncManager.schema.value.states.first {
            $0.name == e.name
        }?.icon
        
        cell?.textLabel?.text = "\(icon == nil ? "" : icon!)\(icon == nil ? "" : " ")\(e.type.rawValue): \(e.name!)"
        cell?.detailTextLabel?.text = dateFormatter.string(from: e.date)
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            SSyncManager.data.value.events.remove(at: eventIndex(forRow: indexPath.row))
            tableView.deleteRows(at: [indexPath], with: .top)
        }
    }
    
}

extension ListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // let e = event(forRow: indexPath.row)
    }
}
