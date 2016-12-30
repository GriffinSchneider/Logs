//
//  ButtonGridView.swift
//  tracker
//
//  Created by Griffin on 10/16/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation
import RxSwift
import RxGesture
import DRYUI

private let PADDING: CGFloat = 10

class ButtonGridView<ButtonDataType: Hashable>: UIView {
    
    let buttons = Variable<[[ButtonDataType]]>([])
    let selection: Observable<ButtonDataType>
    let longPress: Observable<(UIButton, ButtonDataType)>

    private let configBlock: (UIButton, ButtonDataType) -> Void
    private var _selection: Variable<ButtonDataType?> = Variable(nil)
    private var _longPress: Variable<(UIButton, ButtonDataType)?> = Variable(nil)
    private let disposeBag: DisposeBag
    private var outputDisposable: Disposable? = nil
    private var buttonMap: [ButtonDataType: UIButton] = [:]
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    init(config: @escaping (UIButton, ButtonDataType) -> Void) {
        disposeBag = DisposeBag()
        selection = _selection.asObservable().filter { $0 != nil }.map { $0! }
        longPress = _longPress.asObservable().filter { $0 != nil }.map { $0! }
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
                    self.buttonMap[data] = v
                })
            }
        }
        
        // Remove buttons in the map that aren't in the new data
        for (data, button) in foundMap {
            buttonMap.removeValue(forKey: data)
            button.removeFromSuperview()
        }
        
        for (_, button) in buttonMap {
            button.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressed(g:))))
        }
        
        outputDisposable = Observable.from(buttonMap.map { k, v in
            v.rx.tap.asObservable().map { k }
        }).merge().bindTo(_selection)
        
        layoutSubviews()
    }
    
    @objc private func longPressed(g: UILongPressGestureRecognizer) {
        guard g.state == .began else { return }
        for (data, button) in buttonMap {
            if g.view == button {
                _longPress.value = (button, data)
                return
            }
        }
    }
    
    override func layoutSubviews() {
        var lastButton: UIButton? = nil
        var isNewSection = false
        var lines: [[UIButton]] = [[]]
        
        UIView.beginAnimations(nil, context: nil)
        
        for section in self.buttons.value {
            isNewSection = true
            for data in section {
                let v = self.buttonMap[data]!
                self.configBlock(v, data)
                
                v.sizeToFit()
                v.frame.size.width = max(v.frame.size.width, 60)
                
                if let lastButton = lastButton {
                    v.frame.origin.x = lastButton.frame.origin.x + lastButton.frame.size.width + PADDING
                    v.frame.origin.y =  lastButton.frame.origin.y
                    if isNewSection || v.frame.origin.x + v.frame.size.width > v.superview!.frame.size.width {
                        v.frame.origin.x = PADDING
                        v.frame.origin.y = lastButton.frame.origin.y + lastButton.frame.size.height + (isNewSection ? 20 : 10)
                        lines.append([v])
                    } else {
                        lines[lines.count-1].append(v)
                    }
                } else {
                    lines[lines.count-1].append(v)
                    v.frame.origin.x = PADDING
                    v.frame.origin.y = 20
                }
                
                lastButton = v
                isNewSection = false
            }
        }
        
        for line in lines {
            lastButton = nil
            let totalWidth = line.reduce(0) { $0 + $1.frame.size.width }
            let availableWidth = frame.size.width - PADDING*2
            let numPaddings = CGFloat(line.count - 1)
            let requiredTotalWidth = availableWidth - numPaddings*PADDING
            let additionalTotalWidth = requiredTotalWidth - totalWidth
            let amountToGrowEach = additionalTotalWidth / CGFloat(line.count)
            guard  amountToGrowEach > 0 else { continue }
            for button in line {
                button.frame.size.width += amountToGrowEach
                if let lastButton = lastButton {
                    button.frame.origin.x = lastButton.frame.origin.x + lastButton.frame.size.width + PADDING
                }
                lastButton = button
            }
        }
        
        UIView.commitAnimations()
        
        buttonMap.forEach { $0.value.isHighlighted = $0.value.isHighlighted }
    }
}
