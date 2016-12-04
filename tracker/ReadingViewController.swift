//
//  ReadingViewController.swift
//  tracker
//
//  Created by Griffin on 10/30/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import DRYUI

class ReadingViewController: UIViewController {
    let disposeBag = DisposeBag()
    let completion: ([ReadingSchema: Float]) -> Void
    
    private var inputs: [ReadingSchema: Float] = [:]
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    init(completion: @escaping ([ReadingSchema: Float]) -> Void) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SSyncManager.schema.asObservable()
            .map { $0.readings }
            .subscribe(onNext: update)
            .addDisposableTo(disposeBag)
    }
    
    private func update(readings: [ReadingSchema]) {
        view.backgroundColor = UIColor(white: 0, alpha: 0.3)
        view.addSubview(UIButton.self) { v, make in
            v.backgroundColor = UIColor.clear
            v.highlightedBackgroundColor = UIColor(white: 0, alpha: 0.3)
            make.edges.equalTo(v.superview!)
        }.rx.tap
            .subscribe(onNext: { self.completion([:]) })
            .addDisposableTo(self.disposeBag)
        view.addSubview(UIView.self) { v, make in
            v.backgroundColor = UIColor.flatNavyBlueColorDark()
            v.layer.cornerRadius = 5
            v.clipsToBounds = true
            make.center.equalTo(v.superview!)
            make.width.equalTo(v.superview!).offset(-40)
            var lastView: UIView? = nil
            for reading in readings {
                let label = v.addSubview(UILabel.self) { v, make in
                    v.textColor = UIColor.flatWhite()
                    make.left.equalTo(v.superview!).offset(10)
                    make.top.equalTo(lastView?.snp.bottom ?? v.superview!).offset(20)
                    if let lastView = lastView { make.width.equalTo(lastView) }
                }
                let slider = v.addSubview(UISlider.self) { v, make in
                    v.minimumValue = -1
                    v.maximumValue = 10
                    v.value = -1
                    v.minimumTrackTintColor = UIColor.flatGreenColorDark();
                    v.maximumTrackTintColor = UIColor.flatRedColorDark();
                    make.left.equalTo(label.snp.right).offset(10)
                    make.right.equalTo(v.superview!).offset(-10)
                    make.centerY.equalTo(label)
                }
                slider.rx.value.asObservable()
                    .map { "\(reading.name!): \(Int(floorf($0)))" }
                    .bindTo(label.rx.text)
                    .addDisposableTo(self.disposeBag)
                slider.rx.value.asObservable()
                    .subscribe(onNext: {
                        if $0 >= 0 {
                            self.inputs[reading] = $0
                        } else {
                            self.inputs.removeValue(forKey: reading)
                        }
                    })
                    .addDisposableTo(self.disposeBag)
                lastView = label
            }
            v.addSubview(UIButton.self) { v, make in
                v.setTitle("Done", for: .normal)
                v.backgroundColor = UIColor.flatGreenColorDark()
                v.setTitleColor(UIColor.flatWhite(), for: .normal)
                v.contentEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
                v.highlightedBackgroundColor = v.backgroundColor?.darken(byPercentage: 0.4)
                make.top.equalTo(lastView!.snp.bottom).offset(20)
                make.left.right.bottom.equalTo(v.superview!)
            }.rx.tap
                .subscribe(onNext: { self.completion(self.inputs) })
                .addDisposableTo(self.disposeBag)
        }
    }
}
