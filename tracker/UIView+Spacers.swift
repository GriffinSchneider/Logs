//
//  UIView+Spacers.swift
//  tracker
//
//  Created by Griffin Schneider on 11/15/18.
//  Copyright © 2018 griff.zone. All rights reserved.
//

import Foundation
import DRYUI

public extension UIView {

    /// Returns 2 clear views with nothing in them and no constraints, and a block that will
    /// constrain the views' heights to be equal to one another. Useful to center the contents
    /// of a StackView without stretching them.
    ///
    /// The height constraint is applied in a block because the views need to be added to the
    /// StackView before any constraints can be applied between them.
    ///
    /// Use it like this:
    ///
    ///   let pairedSpacers = UIView.pairedSpacerViews(); defer { pair() }
    ///   ... create a StackView with pairedSpacers.topSpacer and pairedSpacers.bottomSpacer in arrangedSubviews ...
    ///
    /// To avoid constraint conflicts, the StackView should use distribution = .fill
    static func pairedSpacers() -> (topSpacer: UIView, bottomSpacer: UIView, pair: () -> Void) {
        let v1 = buildView { v, _ in v.backgroundColor = .clear }
        let v2 = buildView { v, _ in v.backgroundColor = .clear }
        return (v1, v2, { v1.snp.makeConstraints { $0.height.equalTo(v2) } })
    }

    /// Returns 2 clear views with nothing in them and no constraints, and a block that will
    /// constrain the views' widths to be equal to one another. Useful to center the contents
    /// of a StackView without stretching them.
    static func horizontalPairedSpacers() -> (leftSpacer: UIView, rightSpacer: UIView, pair: () -> Void) {
        let v1 = buildView { v, _ in v.backgroundColor = .clear }
        let v2 = buildView { v, _ in v.backgroundColor = .clear }
        return (v1, v2, { v1.snp.makeConstraints { $0.width.equalTo(v2) } })
    }

    /// Adds 2 clear subviews to this view, constrains their heights to be equal to one another, and then returns them.
    func pairedSpacers() -> (topSpacer: UIView, bottomSpacer: UIView) {
        let v1 = addSubview { v, _ in v.backgroundColor = .clear }
        let v2 = addSubview { v, _ in v.backgroundColor = .clear }
        v1.snp.makeConstraints { $0.height.equalTo(v2) }
        return (v1, v2)
    }

    /// Adds 2 clear subviews to this view, constrains their widths to be equal to one another, and then returns them.
    func horizontalPairedSpacers() -> (leftSpacer: UIView, rightSpacer: UIView) {
        let v1 = addSubview { v, _ in v.backgroundColor = .clear }
        let v2 = addSubview { v, _ in v.backgroundColor = .clear }
        v1.snp.makeConstraints { $0.width.equalTo(v2) }
        return (v1, v2)
    }

    /// Returns 2 spacer views that you can use to give things percentage-based horizontal padding.
    /// Adds 2 clear subviews to this view, constrains their widths to be equal to this view's width multiplied by the given percent,
    /// constrains one view to be on this view's left and the other to be on this view's right, and then returns them.
    func horizontalPadders(percent: CGFloat?=nil) -> (leftSpacer: UIView, rightSpacer: UIView) {
        let (left, right) = horizontalPairedSpacers()
        left.snp.makeConstraints { make in
            if let percent = percent {
                make.width.equalToSuperview().multipliedBy(percent)
            }
            make.left.equalToSuperview()
        }
        right.snp.makeConstraints { make in
            make.right.equalToSuperview()
        }
        return (left, right)
    }
}
