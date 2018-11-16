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
    private let done: (Event?) -> Void
    private var event: Event
    
    fileprivate var suggester = Suggester()
    
    private let dateTextField = UITextField()
    fileprivate let noteTextView = UITextView()
    private let linkButton = UIButton()
    private let suggestionsTableView = UITableView()
    private let keyboardView = MVUFKView()
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .medium
        return f
    }()
    
    init(event: Event, done: @escaping (Event?) -> Void) {
        self.done = done
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
        if let idx = SyncManager.data.value.events.index(of: event) {
            let icn = SyncManager.schema.value.icon(for: event)
            navigationItem.title = "\(icn) #\(idx) \(icn)"
        }
    
        view.backgroundColor = UIColor.flatNavyBlueColorDark()

        let stack = StackView(pad: 20)
        view.addSubview(stack.inScrollView(insetPercent: 0.1)) { v, make in
            make.edges.equalToSuperview()
        }

        stack.addSubview(UITextField.self) { v, make in
            v.text = self.event.name
            v.backgroundColor = UIColor.flatNavyBlue()
            v.textColor = UIColor.flatWhiteColorDark()
            v.keyboardAppearance = .dark
            make.height.equalTo(50)

            v.rx.text.subscribe(onNext: { text in
                self.event.name = text ?? ""
                self.suggester.eventName = self.event.name
                self.suggestionsTableView.reloadData()
            }).disposed(by: self.disposeBag)
        }
        stack.addSubview(self.linkButton, Style.ButtonLabel) { v, make in
            v.backgroundColor = EventType.stateColor
            v.setTitle("\(self.event.link?.uuidString ?? "")", for: .normal)
            v.rx.tap.subscribe(onNext: {
                guard let link = self.event.link, let event = SyncManager.data.value.event(forId: link) else {
                    return
                }
                self.push(event: event)
            }).disposed(by: self.disposeBag)
        }
        stack.addSubview(self.dateTextField) { v, make in
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
            }).disposed(by: self.disposeBag)

            make.height.equalTo(50)
        }
        stack.addSubview(self.suggestionsTableView) { v, make in
            v.delegate = self
            v.dataSource = self
            v.backgroundColor = UIColor.flatNavyBlue()
            v.layer.cornerRadius = 5
            v.clipsToBounds = true
            v.separatorColor = UIColor.flatWhiteColorDark()
            make.height.equalToSuperview().priority(UILayoutPriority.defaultHigh)
        }
        stack.addSubview(self.noteTextView) { v, make in
            v.text = self.event.note
            v.backgroundColor = UIColor.flatNavyBlue()
            v.textColor = UIColor.flatWhiteColorDark()
            v.keyboardAppearance = .dark
            make.height.equalTo(200)
            v.rx.text.skip(1).subscribe(onNext: { text in
                self.event.note = text
            }).disposed(by: self.disposeBag)
        }

        stack.subviews.constrainEach { make in
            make.left.right.equalToSuperview()
        }

        view.addSubview(keyboardView) { _, _ in}
        view.addSubview(stack) { v, make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(self.keyboardView.snp.top)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        keyboardView.enabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        keyboardView.enabled = false
    }

    private func push(event: Event) {
        navigationController?.pushViewController(EventViewController(event: event) { newEvent in
            if let newEvent = newEvent, newEvent != event { SyncManager.data.value.events.sortedAppend(newEvent) }
            self.navigationController?.popViewController(animated: true)
        }, animated: true)
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
    var suggestions: [Data.Suggestion] = []
    var eventName: String? = nil {
        didSet {
            suggestions = SyncManager.data.value.noteSuggestions(forEventNamed: eventName)
        }
    }
}

extension EventViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let suggestion = suggester.suggestions[indexPath.row]
        var note = self.noteTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        while !note.isEmpty && !note.hasSuffix("\n\n") {
            note += "\n"
        }
        note += suggestion.text ?? ""
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
            cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
            cell?.textLabel?.textColor = UIColor.flatWhiteColorDark()
            cell?.textLabel?.font = UIFont.systemFont(ofSize: 10, weight: .thin)
            cell?.detailTextLabel?.textColor = UIColor.flatWhiteColorDark().darken(byPercentage: 0.2)
            cell?.detailTextLabel?.font = UIFont.systemFont(ofSize: 10, weight: .ultraLight)
            cell?.backgroundColor = UIColor.flatNavyBlue()
            cell?.selectedBackgroundView = UIView()
            cell?.selectedBackgroundView?.backgroundColor = UIColor.flatNavyBlue().darken(byPercentage: 0.1)
        }
        cell?.textLabel?.text = suggestion.text
        cell?.detailTextLabel?.text = String(suggestion.count)
        return cell!
    }
}
