//
//  StackView.swift
//  tracker
//
//  Created by Griffin Schneider on 11/15/18.
//  Copyright © 2018 griff.zone. All rights reserved.
//

import Foundation
import DRYUI

/// Views added as subviews to this view are stacked vertically. The first view will have its top constrained to
/// this view's top, and any subsequent views will have their tops constrained to the previous view's bottom.
/// This view doesn't do anything to the horizontal axis of its subviews.
public class StackView: UIView {
    private let pad: CGFloat
    public required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    /// - parameter pad: The amount of vertical padding in points between subviews of this view
    public required init(pad: CGFloat = 0, frame: CGRect = .zero) {
        self.pad = pad
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    override public func addSubview(_ view: UIView) {
        let maybeLast = subviews.last
        super.addSubview(view)
        view.snp.makeConstraints { make in
            make.bottom.lessThanOrEqualToSuperview().offset(-1 * pad)
            if let last = maybeLast {
                make.top.equalTo(last.snp.bottom).offset(pad)
            } else {
                make.top.equalToSuperview()
            }
        }
    }
}

extension StackView {
    /// - parameter insetPercent: The left and right inset of the stack view inside the returned scrollview, expressed as a percentage of the width of the scrollview.
    public func inScrollView(insetPercent: CGFloat = 0) -> UIScrollView {
        let scrollView = UIScrollView()
        let (left, right) = scrollView.horizontalPadders(percent: insetPercent)
        scrollView.addSubview(self) { v, make in
            make.top.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
            make.left.equalTo(left.snp.right)
            make.right.equalTo(right.snp.left)
            make.width.equalToSuperview().multipliedBy(1 - (insetPercent * 2))
        }
        return scrollView
    }
}


