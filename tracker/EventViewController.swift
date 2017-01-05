//
//  EventViewController.swift
//  tracker
//
//  Created by Griffin on 11/1/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation
import UIKit
import DRYUI
import MoveViewUpForKeyboardKit
import RxSwift
import RxCocoa

class EventViewController: UIViewController {
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private let disposeBag = DisposeBag()
    private let done: (SEvent?) -> Void
    private var event: SEvent
    
    fileprivate var suggester = Suggester()
    
    private let dateTextField = UITextField()
    fileprivate let noteTextView = UITextView()
    private let suggestionsTableView = UITableView()
    private let keyboardView = MVUFKView()
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .medium
        return f
    }()
    
    init(event: SEvent, done: @escaping (SEvent?) -> Void) {
        self.done = done
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
        if let idx = SSyncManager.data.value.events.index(of: event) {
            let icn = SSyncManager.schema.value.icon(for: event)
            navigationItem.title = "\(icn) #\(idx) \(icn)"
        }
    
        view.backgroundColor = UIColor.flatNavyBlueColorDark()
        
        view.addSubview(keyboardView) { _ in}
        view.addSubview { v, make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(self.keyboardView.snp.top)
            v.addSubview(self.noteTextView) { v, make in
                v.text = self.event.note
                v.backgroundColor = UIColor.flatNavyBlue()
                v.textColor = UIColor.flatWhiteColorDark()
                v.keyboardAppearance = .dark
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview().offset(-10)
                make.height.equalTo(200)
                v.rx.text.subscribe(onNext: { text in
                    self.event.note = text
                }).addDisposableTo(self.disposeBag)
            }
            v.addSubview(self.suggestionsTableView) { v, make in
                v.delegate = self
                v.dataSource = self
                v.backgroundColor = UIColor.flatNavyBlue()
                v.layer.cornerRadius = 5
                v.clipsToBounds = true
                v.separatorColor = UIColor.flatWhiteColorDark()
                make.bottom.equalTo(self.noteTextView.snp.top).offset(-10)
                make.left.right.equalToSuperview().inset(10)
                make.height.equalToSuperview().priority(UILayoutPriorityDefaultHigh)
            }
            v.addSubview(self.dateTextField) { v, make in
                v.text = self.dateFormatter.string(from: self.event.date)
                v.textColor = UIColor.flatWhiteColorDark()
                v.backgroundColor = UIColor.flatNavyBlue()
                
                let picker = UIDatePicker()
                picker.date = self.event.date
                v.inputView = picker
                
                let keyboardDoneButtonView = UIToolbar()
                keyboardDoneButtonView.barStyle = .black
                keyboardDoneButtonView.isTranslucent = true
                keyboardDoneButtonView.tintColor = nil
                keyboardDoneButtonView.sizeToFit()
                
                let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.keyboardDoneButtonPressed))
                keyboardDoneButtonView.setItems([doneButton], animated: true)
                v.inputAccessoryView = keyboardDoneButtonView
                
                picker.rx.date.asObservable().subscribe(onNext: { date in
                    self.event.date = date
                    v.text = self.dateFormatter.string(from: date)
                }).addDisposableTo(self.disposeBag)
                
                make.left.right.equalToSuperview()
                make.bottom.equalTo(self.suggestionsTableView.snp.top).offset(-10)
                make.height.equalTo(50)
            }
            v.addSubview(UITextField.self) { v, make in
                v.text = self.event.name
                v.backgroundColor = UIColor.flatNavyBlue()
                v.textColor = UIColor.flatWhiteColorDark()
                v.keyboardAppearance = .dark
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(10)
                make.bottom.equalTo(self.dateTextField.snp.top).offset(-10)
                make.height.equalTo(50)
                
                v.rx.text.subscribe(onNext: { text in
                    self.event.name = text
                    self.suggester.eventName = self.event.name
                    self.suggestionsTableView.reloadData()
                }).addDisposableTo(self.disposeBag)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        keyboardView.enabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        keyboardView.enabled = false
    }
    
    @objc private func keyboardDoneButtonPressed() {
        view.endEditing(true)
    }
    
    @objc private func doneButtonPressed() {
        done(event)
    }
    
    @objc private func cancelButtonPressed() {
        done(nil)
    }
}

private class Suggester {
    var suggestions: [String?] = []
    var eventName: String? = nil {
        didSet {
            guard let eventName = eventName else { return }
            suggestions = SSyncManager.data.value.events
                .reversed()
                .filter { $0.name == eventName }
                .flatMap {(e: SEvent) -> [String?] in e.note?.components(separatedBy: "\n") ?? [] }
                .map { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !($0 == nil || $0!.isEmpty) }
        }
    }
}

extension EventViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let suggestion = suggester.suggestions[indexPath.row] else { return }
        var note = self.noteTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        while !note.isEmpty && !note.hasSuffix("\n\n") {
            note += "\n"
        }
        note += suggestion
        noteTextView.text = note
    }
}

extension EventViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggester.suggestions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let suggestion = suggester.suggestions[indexPath.row]
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
            cell?.textLabel?.textColor = UIColor.flatWhiteColorDark()
            cell?.textLabel?.font = UIFont.systemFont(ofSize: 10, weight: UIFontWeightThin)
            cell?.backgroundColor = UIColor.flatNavyBlue()
            cell?.selectedBackgroundView = UIView()
            cell?.selectedBackgroundView?.backgroundColor = UIColor.flatNavyBlue().darken(byPercentage: 0.1)
        }
        cell?.textLabel?.text = suggestion
        return cell!
    }
}
