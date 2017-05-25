//
//  Popover.swift
//  tracker
//
//  Created by Griffin Schneider on 5/25/17.
//  Copyright © 2017 griff.zone. All rights reserved.
//

import Foundation
import Popover
import RxCocoa
import RxSwift

struct PopoverButtonInfo {
    let title: String
    let config: (UIButton) -> Void
    let tap: () -> Void
}

func popover(
    inView: UIView,
    onButton button: UIButton,
    disposeBag: DisposeBag,
    buttons: [PopoverButtonInfo],
    barButtons: [PopoverButtonInfo] = []
    ) {
    guard buttons.count > 0 else { return }
    
    let direction = button.frame.origin.y + button.frame.size.height > (inView.frame.size.height / 2)
        ? PopoverType.up : PopoverType.down
    
    let popover = Popover(options: [
        .color(UIColor.flatNavyBlueColorDark()),
        .animationIn(0.1),
        .animationOut(0.1),
        .type(direction)
    ])
    
    var buttons = buttons
    if direction == .up { buttons.reverse() }
    
    let view = UIView(frame: CGRect(x: 0, y: 0, width: 250, height: 0))
    
    let barView = UIView(frame: view.frame)
    view.addSubview(barView)
    
    let scrollView = UIScrollView(frame: view.frame)
    view.addSubview(scrollView)
    
    buttons.forEach { b in
        let button = makeButton(b, popover, disposeBag, scrollView.frame.size.width - 14)
        let y: CGFloat
        if let last = scrollView.subviews.last {
            y =  last.frame.origin.y + last.frame.size.height + 7
        } else {
            y = (direction == .down ? 0 : 7)
        }
        button.frame = CGRect(
            x: 7,
            y: y,
            width: scrollView.frame.size.width - 14,
            height: button.frame.size.height
        )
        scrollView.addSubview(button)
    }
    
    barButtons.forEach { b in
        let width = (view.frame.size.width - 7 - CGFloat(7*barButtons.count)) / CGFloat(barButtons.count)
        let button = makeButton(b, popover, disposeBag, width)
        let x: CGFloat
        if let last = barView.subviews.last {
            x = last.frame.origin.x + last.frame.size.width + 7
        } else {
            x = 7
        }
        button.frame = CGRect(
            x: x,
            y: 7,
            width: width,
            height: button.frame.size.height
        )
        barView.addSubview(button)
    }
    
    let barHeight = (barView.subviews.last?.frame.size.height ?? -14) + 14
    let last = scrollView.subviews.last!
    let bottom = last.frame.origin.y + last.frame.size.height + (direction == .down ? 7 : 0)
    
    view.frame = CGRect(
        x: 0,
        y: 0,
        width: view.frame.size.width,
        height: min(bottom + barHeight, 300)
    )

    barView.frame = CGRect(
        x: 0,
        y: direction == .down ? 0 : view.frame.size.height - barHeight,
        width: view.frame.size.width,
        height: barHeight
    )
    
    scrollView.frame = CGRect(
        x: 0,
        y: direction == .up ? 0 : barHeight,
        width: view.frame.size.width,
        height: view.frame.size.height - barHeight
    )
    scrollView.contentSize = CGSize(width: view.frame.size.width, height: bottom)
    
    if direction == .up {
        scrollView.setContentOffset(CGPoint(x: 0, y:scrollView.contentSize.height - scrollView.frame.size.height), animated: false)
    }
    
    popover.show(view, fromView: button, inView: inView)
}

private func makeButton(_ b: PopoverButtonInfo, _ popover: Popover, _ disposeBag: DisposeBag, _ width: CGFloat) -> UIButton {
    let button = UIButton()
    button.titleLabel?.lineBreakMode = .byWordWrapping
    button.titleLabel?.textAlignment = .center
    button.titleLabel?.numberOfLines = 0
    button.setTitle(b.title, for: .normal)
    b.config(button)
    Style.ButtonLabel(button)
    let size = NSString(string: b.title) .boundingRect(
        with: CGSize(width: width, height: 9999),
        options: .usesLineFragmentOrigin,
        attributes: [NSFontAttributeName: button.titleLabel!.font],
        context: nil
    )
    button.frame.size = CGSize(width: width, height: size.height + 7)
    button.rx.tap.subscribe(onNext: {
        b.tap()
        popover.dismiss()
    }).addDisposableTo(disposeBag)
    return button
}
