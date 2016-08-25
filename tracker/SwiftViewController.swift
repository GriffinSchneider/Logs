//
//  SwiftViewController.swift
//  tracker
//
//  Created by Griffin on 8/25/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import DRYUI



class SwiftViewController: UIViewController {
    
    let sm = SyncManager.i()
    
    
//  - (UIView *)buildRowInView:(UIView *)superview withLastView:(UIView *)lastVieww titles:(NSArray<NSString *> *)titles buttonBlock:(void (^)(UIButton *b, NSString *title))buttonBlock {
//      __block UIView *lastView = lastVieww;
//      build_subviews(superview) {
//          [titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
//              UIButton *add_subview(button) {
//                  [_ setTitleColor:FlatWhiteDark forState:UIControlStateNormal];
//                  [_ setTitle:title forState:UIControlStateNormal];
//                  _.layer.cornerRadius = 5;
//                  _.adjustsImageWhenHighlighted = YES;
//                  make.top.equalTo(lastView);
//                  buttonBlock(_, title);
//                  _.highlightedBackgroundColor = [_.backgroundColor darkenByPercentage:0.2];
//                  if (idx == 0) {
//                      make.left.equalTo(superview).with.offset(10);
//                  } else {
//                      make.width.equalTo(lastView);
//                      make.left.equalTo(lastView.mas_right).with.offset(10);
//                  }
//                  if (idx == titles.count-1) {
//                      make.right.equalTo(superview.superview).with.offset(-10);
//                  }
//              };
//              lastView = button;
//          }];
//      }
//      return lastView;
//  }
    
    
    override func loadView() {
        view = UIView()
        
        if DBCl
        
        view.backgroundColor = UIColor.flatNavyBlueColorDark()
        let a = sm.schema()
        
        let states = sm.schema().states as! [StateSchema]
        var lastView = view.addSubview {v, make in }
        
        0.stride(to: states.count, by: 4).forEach { idx in
            let endIdx = idx.advancedBy(4, limit: states.count)
            let titles: [String] = Array(states[idx ..< endIdx]).map { $0.name }
            lastView = buildRow(superview: view, lastView: lastView, titles: titles) {b, title in
            }
        }
    }
    
    func buildRow(superview superview: UIView, lastView: UIView, titles: [String], buttonBlock: (b: UIButton, title: String)->Void) -> UIView {
        for (idx, t) in titles.enumerate() {
            view.addSubview(UIButton.self) {b, make in
                b.setTitleColor(UIColor.flatWhiteColorDark(), forState: .Normal)
                b.setTitle(title, forState: .Normal)
                b.layer.cornerRadius = 5
                b.adjustsImageWhenDisabled = true
                make.top.equalTo(lastView)
                buttonBlock(b: b, title: t)
                b.highlightedBackgroundColor = b.backgroundColor?.darkenByPercentage(0.2)
                if idx == 0 {
                    make.left.equalTo(b.superview!).offset(10)
                } else {
                    make.width.equalTo(lastView)
                    make.left.equalTo(lastView.snp_right).offset(10)
                }
                if idx == titles.count - 1 {
                    make.right.equalTo(b.superview!.superview!).offset(-10)
                }
            }
        }
        return lastView
    }
    
}