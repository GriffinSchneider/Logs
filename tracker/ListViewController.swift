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
            v.separatorStyle = .none
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
        let e = event(forRow: indexPath.row)
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! ListTableCell?
        if cell == nil {
            cell = ListTableCell(reuseIdentifier: "cell")
        }
        cell?.event = e
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


class ListTableCell: UITableViewCell {
    
    private let nameLabel = UILabel()
    private let typeLabel = UILabel()
    private let dateLabel = UILabel()
    private let icon = UILabel()
    private let circle = CAShapeLayer()
    private let bottomLine = UIView()
    
    private static let dateFormatter: DateFormatter = {
        let t = DateFormatter()
        t.dateStyle = .medium
        t.timeStyle = .medium
        return t
    }()
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    init(reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        buildView()
    }
    
    var event: SEvent? = nil {
        didSet {
            guard let event = event else { return }
            let i = SSyncManager.schema.value.icon(for: event)
            icon.text = i
            icon.backgroundColor = event.color
            circle.isHidden = !i.isEmpty
            nameLabel.text = event.name
            typeLabel.text = event.type.rawValue
            dateLabel.text = ListTableCell.dateFormatter.string(from: event.date)
        }
    }
    
    private func buildView() {
        backgroundColor = UIColor.flatNavyBlueColorDark()
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor.flatNavyBlue().lighten(byPercentage: 0.1)
        contentView.addSubview(icon) { v, _ in
            v.layer.cornerRadius = 5
            v.clipsToBounds = true
            v.textAlignment = .center
            v.textColor = UIColor.flatNavyBlueColorDark()
            self.circle.fillColor = UIColor.flatNavyBlueColorDark().cgColor
            v.layer.addSublayer(self.circle)
        }
        contentView.addSubview(nameLabel) { v, _ in
            v.textColor = UIColor.flatWhiteColorDark()
            v.font = UIFont.systemFont(ofSize: 16)
        }
        contentView.addSubview(typeLabel) { v, _ in
            v.textColor = UIColor.flatWhiteColorDark()
            v.font = UIFont.systemFont(ofSize: 9, weight: UIFontWeightLight)
        }
        contentView.addSubview(dateLabel) { v, _ in
            v.textColor = UIColor.flatWhiteColorDark()
            v.textAlignment = .right
            v.font = UIFont.systemFont(ofSize: 9, weight: UIFontWeightLight)
        }
        contentView.addSubview(bottomLine) { v, _ in
            v.backgroundColor = UIColor.flatWhiteColorDark().withAlphaComponent(0.3)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let size = self.contentView.frame.size.height - 8
        icon.frame = CGRect(x: 10, y: 4, width: size, height: size)
        
        circle.path = UIBezierPath(
            arcCenter: CGPoint(x: size/2, y: size/2),
            radius: CGFloat(size/2 - 10.0),
            startAngle: 0,
            endAngle:CGFloat(M_PI) * 2,
            clockwise: true
        ).cgPath
        
        nameLabel.sizeToFit()
        let x = icon.frame.origin.x + icon.frame.size.width + 12
        nameLabel.frame = CGRect(
            x: x,
            y: icon.frame.origin.y + 1,
            width: contentView.frame.size.width - x,
            height: nameLabel.frame.size.height
        )
        
        typeLabel.sizeToFit()
        let y = nameLabel.frame.origin.y + nameLabel.frame.size.height
        typeLabel.frame = CGRect(
            x: nameLabel.frame.origin.x,
            y: y,
            width: nameLabel.frame.size.width,
            height: icon.frame.origin.y + icon.frame.size.height - y
        )
        
        dateLabel.sizeToFit()
        dateLabel.frame = CGRect(
            x: contentView.frame.size.width - dateLabel.frame.size.width - 15,
            y: typeLabel.frame.origin.y,
            width: dateLabel.frame.size.width,
            height: typeLabel.frame.size.height
        )
        
        bottomLine.frame = CGRect(
            x: nameLabel.frame.origin.x,
            y: contentView.frame.size.height - 0.5,
            width: dateLabel.frame.origin.x + dateLabel.frame.size.width - nameLabel.frame.origin.x,
            height: 0.5
        )
    }
    
}
