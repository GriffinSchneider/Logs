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
    
    private let dateTextField = UITextField()
    private let noteTextView = UITextView()
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
        view.addSubview(noteTextView) { v, make in
            v.text = self.event.note
            v.backgroundColor = UIColor.flatNavyBlue()
            v.textColor = UIColor.flatWhiteColorDark()
            v.keyboardAppearance = .dark
            make.left.right.equalToSuperview()
            make.height.equalTo(200)
            make.bottom.equalTo(self.keyboardView).offset(-10)
            v.rx.text.subscribe(onNext: { text in
                self.event.note = text
            }).addDisposableTo(self.disposeBag)
        }
        view.addSubview(dateTextField) { v, make in
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
            make.bottom.equalTo(self.noteTextView.snp.top).offset(-10)
            make.height.equalTo(50)
        }
        view.addSubview(UITextField.self) { v, make in
            v.text = self.event.name
            v.backgroundColor = UIColor.flatNavyBlue()
            v.textColor = UIColor.flatWhiteColorDark()
            v.keyboardAppearance = .dark
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.dateTextField.snp.top).offset(-10)
            make.height.equalTo(50)
            
            v.rx.text.subscribe(onNext: { text in
                self.event.name = text
            }).addDisposableTo(self.disposeBag)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        keyboardView.enabled = true
        dateTextField.becomeFirstResponder()
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
