/*
 Created by DessLi on 2019/05/07
 */

import Foundation
import UIKit

fileprivate let DPMargin:CGFloat = 0
fileprivate let DPHeight:CGFloat = 270
public typealias Callback = (Date, [String:String]) -> ()
fileprivate var showComponentKeys = [String]()

struct DPData {
    var date: Date
    var wildcardSelectd: [String:String]
}

public class PopupDatePicker: UIView {
    
    fileprivate var callback: Callback?
    
    fileprivate var dpDataArray = [String:[String]]()
    fileprivate var dateComponentCell = Array<String>()
    fileprivate var dpData = DPData(date: Date(), wildcardSelectd: [String : String]())
    fileprivate var dpDataCache = ["yyyy": 0, "MM": 0, "dd": 0, "HH": 0, "mm": 0, "ss": 0]
    fileprivate var dpShowType: String = "yyyy-MM-dd"
    fileprivate var wildcardArray = [String:Array<String>]()
    
    fileprivate var datePicker: UIPickerView = {
        let datePicker = UIPickerView()
        datePicker.showsSelectionIndicator = false
        return datePicker
    }()
    
    fileprivate var backWindow: UIWindow = {
        let backWindow = UIWindow(frame: UIScreen.main.bounds)
        backWindow.windowLevel = UIWindow.Level.statusBar
        backWindow.backgroundColor = UIColor(white: 0, alpha: 0.3)
        backWindow.isHidden = true
        return backWindow
    }()
    
    fileprivate var localLanguage: String = {
        let def = UserDefaults.standard
        let allLanguages: [String] = def.object(forKey: "AppleLanguages") as! [String]
        var chooseLanguage = allLanguages.first
        if chooseLanguage?.range(of: "zh") != nil {
            return "zh"
        }
        return "en"
    }()
    
    fileprivate var minLimitDate = Date.init(timeIntervalSince1970: TimeInterval(0))
    fileprivate var maxLimitDate = Date.init(timeIntervalSince1970: TimeInterval(9999999999))

    /// PopupDatePicker
    ///
    /// - Parameters:
    ///   - currentDate: Current Date
    ///   - minLimitDate: min limit Date
    ///   - maxLimitDate: max limit Date
    ///   - dpShowType:
    /*
     - yyyy: year 1970
     - MM: month 01
     - dd: day 01
     - HH: hours 0..23
     - mm: minutes 0..59
     - ss: seconds 0..59
     - $: splitter of components for the picker view. yyyy$MM$dd
     - -: splitter of Year month day. yyyy-MM-dd
     - :: splitter of hour minute second. HH:mm:dd
     - ?{key}?: wildcard, something like ?hourange? the hourange is key, if use this flag you need set wildcard array
    */
    ///   - wildcardArray: if use DPShowType ?? flag you need set this param. Set DPShowType like ?key?$?key1? then set wildcardArray ["key":[ "a", "b" ], "key1":[ "c", "d" ]]
    ///   - wildcardDefaults: wildcardDefaults ["key": "value"]
    ///   - callback: (Date, [String:String]) -> (), first param is selected Date, second params is wildcard selected data
    public init(currentDate: Date?, minLimitDate: Date?, maxLimitDate: Date?, dpShowType: String?, wildcardArray: [String:Array<String>]?, wildcardDefaults:[String:String]?, _ callback: @escaping Callback) {
        super.init(frame: CGRect.zero)
        let nowDate = Date()
        let currentDate = currentDate ?? nowDate
        dpDataCache["yyyy"] = nowDate.getComponent(component: .year)
        dpDataCache["MM"] = nowDate.getComponent(component: .month)
        dpDataCache["dd"] = nowDate.getComponent(component: .day)
        dpDataCache["HH"] = nowDate.getComponent(component: .hour)
        dpDataCache["mm"] = nowDate.getComponent(component: .minute)
        dpDataCache["ss"] = nowDate.getComponent(component: .second)
        self.minLimitDate = minLimitDate ?? Date.init(timeIntervalSince1970: TimeInterval(0))
        if maxLimitDate != nil {
            self.maxLimitDate = maxLimitDate!
        } else {
            var dateComponent = DateComponents()
            dateComponent.year = 1
            self.maxLimitDate = Calendar.current.date(byAdding: dateComponent, to: Date()) ?? Date()
        }
        if dpShowType != nil {
            self.dpShowType = dpShowType!
        }
        var baseWildcardArray = [String:String]()
        if wildcardArray != nil {
            self.wildcardArray = wildcardArray!
            if wildcardDefaults == nil {
                for (k, v) in wildcardArray! {
                    baseWildcardArray[k] = v[0]
                }
            }
        }
        self.callback = callback
        dpData = DPData(date: currentDate, wildcardSelectd: wildcardDefaults ?? baseWildcardArray)
        dpLayout()
        createDPData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func dpLayout() {
        backgroundColor = UIColor.white
        layer.cornerRadius = 0
        clipsToBounds = true
        datePicker.delegate = self
        datePicker.dataSource = self
        datePicker.backgroundColor = UIColor.clear
        addSubview(datePicker)
        datePicker.addLayout(attributes: [.left,.right,.top], toItem: self, constants: [0,0,54])
        
        // Done Button
        let doneButtonTitle = self.localLanguage == "zh" ? "确定" : "OK"
        let doneButton = UIButton(type: .custom)
        doneButton.setTitleColor(UIColor.black, for: .normal)
        doneButton.setTitle(doneButtonTitle, for: .normal)
        doneButton.backgroundColor = UIColor.white
        doneButton.addTarget(self, action: #selector(PopupDatePicker.doneButtonHandle), for: .touchUpInside)
        addSubview(doneButton)
        doneButton.addLayout(attributes: [.left,.top,.height], toItem: self, constants: [15,0,54])
        
        // Cancel Button
        let cancelButtonTitle = self.localLanguage == "zh" ? "取消" : "Cancel"
        let cancelButton = UIButton(type: .custom)
        cancelButton.setTitle(cancelButtonTitle, for: .normal)
        cancelButton.setTitleColor(.black, for: .normal)
        cancelButton.backgroundColor = .white
        cancelButton.addTarget(self, action: #selector(PopupDatePicker.cancelButtonHandle), for: .touchUpInside)
        addSubview(cancelButton)
        cancelButton.addLayout(attributes: [.right,.top,.height], toItem: self, constants: [-15,0,54])
        
        // Button Line
        let line:UIView = UIView.init(frame: CGRect.init(x: 0, y: 55, width: UIScreen.main.bounds.size.width, height: 0.5))
        line.backgroundColor = UIColor.lightGray
        addSubview(line)
        backWindow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss)))
    }
    
    func createDPData() {
        let showComponents = self.dpShowType.components(separatedBy: "$")
        for comp in showComponents {
            showComponentKeys.append(comp)
            switch comp {
            case "yyyy":
                dpDataArray[comp] = getYears()
                dateComponentCell.append(comp)
                break
            case "MM":
                dpDataArray[comp] = getMonths()
                dateComponentCell.append(comp)
                break
            case "dd":
                dpDataArray[comp] = getDays()
                dateComponentCell.append(comp)
                break
            case "HH":
                dpDataArray[comp] = getHours()
                dateComponentCell.append(comp)
                break
            case "mm":
                dpDataArray[comp] = getMinutes()
                dateComponentCell.append(comp)
                break
            case "ss":
                dpDataArray[comp] = getSeconds()
                dateComponentCell.append(comp)
                break
            default:
                if comp.range(of: "?") != nil {
                    let flagStartIndex = comp.index(comp.startIndex, offsetBy: 1)
                    let flagEndIndex = comp.index(comp.endIndex, offsetBy: -1)
                    let key = String(comp[flagStartIndex..<flagEndIndex])
                    if self.wildcardArray[key] != nil {
                        dpDataArray[comp] = wildcardArray[key]
                        dateComponentCell.append(comp)
                    }
                    break
                }
                dpDataArray[comp] = getGroupShowComponents(comp: comp)
                dateComponentCell.append(comp)
                break
            }
        }
        datePicker.reloadAllComponents()
        scrollToDate(components: dateComponentCell, animated: false)
    }
    
    func getGroupShowComponents(comp: String) -> Array<String> {
        var groupDate = [String]()
        var maxLevelType = ""
        let yyyy = comp.range(of: "yyyy") != nil ? 1 : 0
        let MM = comp.range(of: "MM") != nil ? getComponentsMaxLevel(level: 2, type: "MM", maxLevel: &maxLevelType) : 0
        let dd = comp.range(of: "dd") != nil ? getComponentsMaxLevel(level: 3, type: "dd", maxLevel: &maxLevelType) : 0
        let HH = comp.range(of: "HH") != nil ? getComponentsMaxLevel(level: 4, type: "HH", maxLevel: &maxLevelType) : 0
        let mm = comp.range(of: "mm") != nil ? getComponentsMaxLevel(level: 6, type: "mm", maxLevel: &maxLevelType) : 0
        let ss = comp.range(of: "ss") != nil ? getComponentsMaxLevel(level: 7, type: "ss", maxLevel: &maxLevelType) : 0
        if (yyyy != 0 || MM != 0 || dd != 0) && (HH != 0 || mm != 0 || ss != 0) {
            fatalError("Time range is too large. You can set yyyy-MM-dd or HH:mm:ss in one date picker components")
        }
        var forDate = minLimitDate
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = comp
        repeat {
            groupDate.append(dateFormatter.string(from: forDate))
            forDate = getGroupShowNextTime(date: forDate, maxLevelType: maxLevelType)
        } while forDate.compare(maxLimitDate) == .orderedAscending
        return groupDate
    }
    
    func getComponentsMaxLevel(level:Int, type:String, maxLevel:inout String) -> Int {
        maxLevel = type
        return level
    }
    
    func getGroupShowNextTime(date:Date, maxLevelType:String) -> Date {
        var dateComponent = DateComponents()
        switch maxLevelType {
        case "MM":
            dateComponent.month = 1
            break
        case "dd":
            dateComponent.day = 1
            break
        case "HH":
            dateComponent.hour = 1
            break
        case "mm":
            dateComponent.minute = 1
        case "ss":
            dateComponent.second = 1
        default: break
        }
        return Calendar.current.date(byAdding: dateComponent, to: date) ?? Date()
    }
    
    func endOfDay(year: Int, month: Int) -> Int {
        var dateComponent = DateComponents()
        dateComponent.year = year
        dateComponent.month = month
        dateComponent.day = 1
        let date = Calendar.current.date(from: dateComponent)
        var endDateComponent = DateComponents()
        endDateComponent.month = 1
        endDateComponent.day = -1
        endDateComponent.second = -1
        let endDate = Calendar.current.date(byAdding: endDateComponent, to: date!)
        return endDate!.getComponent(component: .day)
    }
    
    func getYears() -> Array<String> {
        var years = [String]()
        for year in minLimitDate.getComponent(component: .year)...maxLimitDate.getComponent(component: .year) {
            years.append(String(year))
        }
        return years
    }

    func getMonths() -> Array<String> {
        var months = [String]()
        
        var minMonth = 1
        if Int(dpData.date.getComponent(component: .year)) == minLimitDate.getComponent(component: .year) {
            minMonth = minLimitDate.getComponent(component: .month)
        }
        var maxMonth = 12
        if Int(dpData.date.getComponent(component: .year)) == maxLimitDate.getComponent(component: .year) {
            maxMonth = maxLimitDate.getComponent(component: .month)
        }
        
        for month in minMonth...maxMonth {
            months.append(month < 10 ? ("0" + String(month)):String(month))
        }
        return months
    }

    func getDays() -> Array<String> {
        var days = [String]()
        
        var minDay = 1
        if Int(dpData.date.getComponent(component: .year)) == minLimitDate.getComponent(component: .year) && Int(dpData.date.getComponent(component: .month)) == minLimitDate.getComponent(component: .month) {
            minDay = minLimitDate.getComponent(component: .day)
        }
        var maxDay = getMaxDays(year: Int(dpData.date.getComponent(component: .year)), month: Int(dpData.date.getComponent(component: .month)))
        if Int(dpData.date.getComponent(component: .year)) == maxLimitDate.getComponent(component: .year) && Int(dpData.date.getComponent(component: .month)) == maxLimitDate.getComponent(component: .month) {
            maxDay = maxLimitDate.getComponent(component: .day)
        }
        
        for day in minDay...maxDay {
            days.append(day < 10 ? ("0" + String(day)):String(day))
        }
        return days
    }

    func getHours() -> Array<String> {
        var hours = [String]()
        
        var minHour = 0
        if Int(dpData.date.getComponent(component: .year)) == minLimitDate.getComponent(component: .year) && Int(dpData.date.getComponent(component: .month)) == minLimitDate.getComponent(component: .month) &&
            Int(dpData.date.getComponent(component: .day)) == minLimitDate.getComponent(component: .day) {
            minHour = minLimitDate.getComponent(component: .hour)
        }
        var maxHour = 23
        if Int(dpData.date.getComponent(component: .year)) == maxLimitDate.getComponent(component: .year) && Int(dpData.date.getComponent(component: .month)) == maxLimitDate.getComponent(component: .month) &&
            Int(dpData.date.getComponent(component: .day)) == maxLimitDate.getComponent(component: .day) {
            maxHour = maxLimitDate.getComponent(component: .hour)
        }
        
        for hour in minHour...maxHour {
            hours.append(hour < 10 ? ("0" + String(hour)):String(hour))
        }
        return hours
    }

    func getMinutes() -> Array<String> {
        var minutes = [String]()
        
        var minMinute = 0
        if Int(dpData.date.getComponent(component: .year)) == minLimitDate.getComponent(component: .year) && Int(dpData.date.getComponent(component: .month)) == minLimitDate.getComponent(component: .month) &&
            Int(dpData.date.getComponent(component: .day)) == minLimitDate.getComponent(component: .day) &&
            Int(dpData.date.getComponent(component: .hour)) == minLimitDate.getComponent(component: .hour) {
            minMinute = minLimitDate.getComponent(component: .minute)
        }
        var maxMinute = 59
        if Int(dpData.date.getComponent(component: .year)) == maxLimitDate.getComponent(component: .year) && Int(dpData.date.getComponent(component: .month)) == maxLimitDate.getComponent(component: .month) &&
            Int(dpData.date.getComponent(component: .day)) == maxLimitDate.getComponent(component: .day) &&
            Int(dpData.date.getComponent(component: .hour)) == maxLimitDate.getComponent(component: .hour) {
            maxMinute = maxLimitDate.getComponent(component: .minute)
        }
        
        for minute in minMinute...maxMinute {
            minutes.append(minute < 10 ? ("0" + String(minute)):String(minute))
        }
        return minutes
    }
    
    func getSeconds() -> Array<String> {
        var seconds = [String]()
        for second in 0...59 {
            seconds.append(String(second))
        }
        return seconds
    }
    
    func getMaxDays(year: Int, month: Int) -> Int {
        
        let isLeapYear = year % 4 == 0 ? (year % 100 == 0 ? (year % 400 == 0 ? true:false):true):false
        switch month {
        case 1,3,5,7,8,10,12:
            return 31
        case 4,6,9,11:
            return 30
        case 2:
            return isLeapYear ? 29 : 28
        default:
            return 30
        }
    }
    
    @objc func doneButtonHandle() {
        callback?(dpData.date, dpData.wildcardSelectd)
        dismiss()
    }
    
    @objc func cancelButtonHandle() {
        dismiss()
    }
    
    public func show() {
        
        backWindow.addSubview(self)
        backWindow.makeKeyAndVisible()
        
        frame = CGRect.init(x: DPMargin, y: backWindow.frame.height, width: backWindow.frame.width, height: DPHeight)
        
        UIView.animate(withDuration: 0.3) {
            
            var bottom:CGFloat = 0
            if UIScreen.main.bounds.height == 812 {
                bottom = 44
            }
            
            self.frame = CGRect.init(x: DPMargin, y: self.backWindow.frame.height - DPHeight - bottom, width: self.backWindow.frame.width, height: DPHeight)
        }
    }
    
    @objc public func dismiss() {
        
        UIView.animate(withDuration: 0.3, animations: {
            self.frame = CGRect.init(x: DPMargin, y: self.backWindow.frame.height, width: self.backWindow.frame.width, height: DPHeight)
        }) { (_) in
            self.removeFromSuperview()
            self.backWindow.resignKey()
        }
    }
}

extension PopupDatePicker: UIPickerViewDelegate, UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return dpDataArray.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        let dateComponent = dateComponentCell[component]
        return dpDataArray[dateComponent]?.count ?? 0
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let dateComponent = dateComponentCell[component]
        return dpDataArray[dateComponent]?[row]
        
    }
    
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let dateComponent = dateComponentCell[component]
        var label = UILabel()
        if let v = view {
            label = v as! UILabel
        }
        label.font = UIFont (name: "Helvetica Neue", size: 16)
        label.text =  dpDataArray[dateComponent]?[row]
        label.textAlignment = .center
        return label
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let formatter = DateFormatter()
        let dateComponent = dateComponentCell[component]
        if dateComponent.range(of: "?") != nil {
            let flagStartIndex = dateComponent.index(dateComponent.startIndex, offsetBy: 1)
            let flagEndIndex = dateComponent.index(dateComponent.endIndex, offsetBy: -1)
            let key = String(dateComponent[flagStartIndex..<flagEndIndex])
            dpData.wildcardSelectd[key] = dpDataArray[dateComponent]![row]
        } else if dateComponent.range(of: "-") != nil || dateComponent.range(of: ":") != nil {
            formatter.dateFormat = dateComponent
            let date = formatter.date(from: dpDataArray[dateComponent]![row])
            if dateComponent.range(of: "yyyy") != nil {dpDataCache["yyyy"] = date?.getComponent(component: .year)}
            if dateComponent.range(of: "MM") != nil {dpDataCache["MM"] = date?.getComponent(component: .month)}
            if dateComponent.range(of: "dd") != nil {dpDataCache["dd"] = date?.getComponent(component: .day)}
            if dateComponent.range(of: "HH") != nil {dpDataCache["HH"] = date?.getComponent(component: .hour)}
            if dateComponent.range(of: "mm") != nil {dpDataCache["mm"] = date?.getComponent(component: .minute)}
            if dateComponent.range(of: "ss") != nil {dpDataCache["ss"] = date?.getComponent(component: .second)}
        } else {
            dpDataCache[dateComponent] = Int(dpDataArray[dateComponent]![row])
        }
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dpData.date = formatter.date(from: "\(dpDataCache["yyyy"]!)-\(dpDataCache["MM"]!)-\(dpDataCache["dd"]!) \(dpDataCache["HH"]!):\(dpDataCache["mm"]!):\(dpDataCache["ss"]!)")!
        reload(dateComponent: dateComponent)
    }
}

extension PopupDatePicker {
    func scrollToDate(components:Array<String>, animated: Bool) {
        
        for c in components {
            var timeString: String?
            timeString = dpData.wildcardSelectd[c]
            guard let component = dateComponentCell.firstIndex(of: c),
                let timeStr = timeString,
                let row = dpDataArray[c]?.firstIndex(of: timeStr)
                else {return}
            
            datePicker.selectRow(row, inComponent: component, animated: animated)
        }
    }
    func reload(dateComponent:String) {
        guard let index = dateComponentCell.firstIndex(of: dateComponent) else {return}
        var components = [String]()
        for (i,c) in dateComponentCell.enumerated() {
            if i > index {
                components.append(c)
            }
        }
        scrollToDate(components: components, animated: false)
    }
}

extension UIView {

}
