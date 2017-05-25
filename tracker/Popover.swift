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

func popover(inView: UIView, onButton button: UIButton, withBag disposeBag: DisposeBag, withButtons buttons: [PopoverButtonInfo]) {
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
    let view = UIView()
    view.frame = CGRect(x: 0, y: 0, width: 250, height: 0)
    buttons.forEach { b in
        let button = UIButton()
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0
        button.setTitle(b.title, for: .normal)
        b.config(button)
        Style.ButtonLabel(button)
        let size = NSString(string: b.title) .boundingRect(
            with: CGSize(width: view.frame.size.width - 14, height: 9999),
            options: .usesLineFragmentOrigin,
            attributes: [NSFontAttributeName: button.titleLabel!.font],
            context: nil
        )
        button.frame.size = CGSize(width: size.width, height: size.height + 7)
        let y: CGFloat
        if let last = view.subviews.last {
            y =  last.frame.origin.y + last.frame.size.height + 7
        } else {
            y = 7
        }
        button.frame = CGRect(
            x: 7,
            y: y,
            width: view.frame.size.width - 14,
            height: button.frame.size.height
        )
        button.rx.tap.subscribe(onNext: {
            b.tap()
            popover.dismiss()
        }).addDisposableTo(disposeBag)
        view.addSubview(button)
    }
    let last = view.subviews.last!
    view.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: last.frame.origin.y + last.frame.size.height + 7)
    popover.show(view, fromView: button, inView: inView)
}
