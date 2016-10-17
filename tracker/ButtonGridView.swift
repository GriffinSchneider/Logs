//
//  ButtonGridView.swift
//  tracker
//
//  Created by Griffin on 10/16/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation
import RxSwift
import DRYUI


class ButtonGridView<ButtonDataType: Hashable>: UIView {
    
    let buttons = Variable<[[ButtonDataType]]>([])
    let selection: Observable<ButtonDataType>

    private let configBlock: (UIButton, ButtonDataType) -> Void
    private var _selection: Variable<ButtonDataType?> = Variable(nil)
    private let disposeBag: DisposeBag
    private var outputDisposable: Disposable? = nil
    private var buttonMap: [ButtonDataType: UIButton] = [:]
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    init(config: @escaping (UIButton, ButtonDataType) -> Void) {
        disposeBag = DisposeBag()
        selection = _selection.asObservable().filter { $0 != nil }.map { $0! }
        configBlock = config
        super.init(frame: .zero)
        buttons.asObservable().subscribe(onNext: {[weak self] data in
            self?.display(inputData: data)
        }).addDisposableTo(disposeBag)
        
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(layoutSubviews), userInfo: nil, repeats: true)
    }
    
    private func display(inputData: [[ButtonDataType]]) {
        outputDisposable?.dispose()
        var foundMap = buttonMap
        
        // Add new buttons that aren't already in the map
        for data in inputData.joined() {
            if let found = foundMap.removeValue(forKey: data) {
                // If there was already a button in the map, then replace its key
                // with the new data, since it might be different even if it's 'equal'
                // to the old data
                buttonMap.removeValue(forKey: data)
                buttonMap[data] = found
            } else {
                self.addSubview(UIButton.self, { v in
                    v.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
                    buttonMap[data] = v
                })
            }
        }
        
        // Remove buttons in the map that aren't in the new data
        for (data, button) in foundMap {
            buttonMap.removeValue(forKey: data)
            button.removeFromSuperview()
        }
        
        outputDisposable = Observable.from(buttonMap.map { t -> Observable<ButtonDataType?> in
            let (key, value) = t
            return value.rx.tap.asObservable().map { key }
        }).merge().bindTo(_selection)
    }
    
    override func layoutSubviews() {
        var lastButton: UIButton? = nil
        var isNewSection = false
        
        UIView.beginAnimations(nil, context: nil)
        
        for section in self.buttons.value {
            isNewSection = true
            for data in section {
                let v = self.buttonMap[data]!
                self.configBlock(v, data)
                
                v.sizeToFit()
                v.frame.size.width = max(v.frame.size.width, 60)
                
                if let lastButton = lastButton {
                    v.frame.origin.x = lastButton.frame.origin.x + lastButton.frame.size.width + 10
                    v.frame.origin.y =  lastButton.frame.origin.y
                    if isNewSection || v.frame.origin.x + v.frame.size.width > v.superview!.frame.size.width {
                        v.frame.origin.x = 10
                        v.frame.origin.y = lastButton.frame.origin.y + lastButton.frame.size.height + (isNewSection ? 20 : 10)
                    }
                } else {
                    v.frame.origin.x = 10
                    v.frame.origin.y = 20
                }
                
                lastButton = v
                isNewSection = false
            }
        }
        
        UIView.commitAnimations()
    }
}
