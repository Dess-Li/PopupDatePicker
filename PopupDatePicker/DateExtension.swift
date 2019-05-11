/*
 DateExtension.swift
 PopupDatePicker
 
 Created by DessLi on 2019/05/11.
 Copyright © 2019. All rights reserved.
 */


import Foundation
extension Date {
    public func getComponent(component: Calendar.Component) -> Int {
        let calendar = Calendar.current
        return calendar.component(component, from: self)
    }
}
