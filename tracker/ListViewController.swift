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

class Filterer {
    private var filtered: [SEvent] = []
    private var search: String = ""
    private let disposeBag = DisposeBag()
    init() {
        SSyncManager.data.asObservable().subscribe(onNext: { data in
            self.search = ""
        }).addDisposableTo(disposeBag)
    }
    func filteredEvents(search _s: String?) -> [SEvent] {
        var s = _s ?? ""
        if s.isEmpty {
            return SSyncManager.data.value.events
        } else if s != search {
            search = s
            s = s.lowercased()
            if s.characters.last == " " {
                s = s.trimmingCharacters(in: .whitespaces)
                filtered = SSyncManager.data.value.events.filter{ e in
                    e.name.lowercased() == s
                }
            } else {
                filtered = SSyncManager.data.value.events.filter{ e in
                    e.name.lowercased().range(of: s) != nil
                }
            }
        }
        return filtered
    }
}

class ListViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    private let completion: () -> Void
    fileprivate let searchTextField: UITextField
    fileprivate let tableView: UITableView
    fileprivate let dateFormatter: DateFormatter = {
        let t = DateFormatter()
        t.dateStyle = .medium
        t.timeStyle = .medium
        return t
    }()
    
    fileprivate let filterer = Filterer()
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    init(completion: @escaping () -> Void) {
        self.completion = completion
        self.tableView = UITableView()
        self.searchTextField = UITextField()
        super.init(nibName: nil, bundle: nil)
        edgesForExtendedLayout = []
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
        view.backgroundColor = UIColor.flatNavyBlueColorDark()
        view.addSubview(searchTextField) { v, make in
            v.autocapitalizationType = .none
            v.autocorrectionType = .no
            v.layer.cornerRadius = 5
            v.clipsToBounds = true
            v.backgroundColor = UIColor.flatNavyBlue()
            v.textColor = UIColor.flatWhite()
            v.keyboardAppearance = .dark
            v.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
            v.leftViewMode = .always
            v.attributedPlaceholder = NSAttributedString(string: "Search", attributes: [
                NSForegroundColorAttributeName: UIColor.flatWhiteColorDark()
            ])
            v.rx.text.subscribe(onNext: { search in
                self.tableView.reloadData()
            }).addDisposableTo(self.disposeBag)
            make.height.equalTo(35)
            make.left.right.top.equalToSuperview().inset(10)
        }
        view.addSubview(tableView) { v, make in
            v.delegate = self
            v.dataSource = self
            v.backgroundColor = UIColor.flatNavyBlueColorDark()
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.searchTextField.snp.bottom).offset(10)
        }
    }
    
    fileprivate func eventIndex(forRow row: Int) -> Int {
        return filterer.filteredEvents(search: searchTextField.text).count - row - 1
    }
    
    fileprivate func event(forRow row: Int) -> SEvent {
        return filterer.filteredEvents(search: searchTextField.text)[eventIndex(forRow: row)]
    }
    
    @objc private func doneButtonPressed() {
        completion()
    }
}

extension ListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterer.filteredEvents(search: searchTextField.text).count
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
            SSyncManager.data.value.events.remove(
                at: SSyncManager.data.value.events.index(of: event(forRow: indexPath.row))!
            )
            tableView.deleteRows(at: [indexPath], with: .top)
        }
    }
    
}

extension ListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let oldEvent = event(forRow: indexPath.row)
        navigationController?.pushViewController(EventViewController(event: oldEvent) { newEvent in
            if let e = newEvent {
                let idx = SSyncManager.data.value.events.index(of: oldEvent)
                SSyncManager.data.value.events[idx!] = e
                SSyncManager.data.value.events.sort()
                self.tableView.reloadData()
            }
            let _ = self.navigationController?.popViewController(animated: true)
        }, animated: true)
    }
}
