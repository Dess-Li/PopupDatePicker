/*
  UIViewExtension.swift
  PopupDatePicker

  Created by DessLi on 2019/05/11.
  Copyright © 2019. All rights reserved.
*/

import UIKit

extension UIView {
    func addLayout(attributes attr1s: [NSLayoutConstraint.Attribute],
                   relatedBy relation: NSLayoutConstraint.Relation = .equal,
                   toItem: Any?,
                   multiplier: CGFloat = 1,
                   constants: [CGFloat]) {
        if translatesAutoresizingMaskIntoConstraints == true {
            translatesAutoresizingMaskIntoConstraints = false
        }
        for (i,attr1) in attr1s.enumerated() {
            var attr2: NSLayoutConstraint.Attribute = attr1
            var toItem = toItem
            if attr1 == .width || attr1 == .height {
                toItem = nil
                attr2 = .notAnAttribute
            }
            let constant = constants[i]
            let constraint = NSLayoutConstraint.init(item: self, attribute: attr1, relatedBy: relation, toItem: toItem, attribute: attr2, multiplier: 1, constant: constant)
            NSLayoutConstraint.activate([constraint])
        }
    }
}
