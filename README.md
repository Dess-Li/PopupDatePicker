<h1 align="center"> PopupDatePicker </h1>
<p align="center">
<a href="https://opensource.org/licenses/MIT"><img alt="Licence" src="https://img.shields.io/badge/license-MIT-green.svg" /></a>
<a href=""><img alt="Version" src="https://img.shields.io/badge/version-1.0.0-blue.svg" /></a>
<a href=""><img alt="Swift Version" src="https://img.shields.io/badge/swift_versions-5.0-orange.svg" /></a>
<a href="https://cocoapods.org/pods/PopupDatePicker"><img alt="Licence" src="https://img.shields.io/badge/pod-PopupDatePicker-red.svg" /></a>
</p>



<p align="center">
<img width="30%" height="auto" alt="Cards Feed" src="https://github.com/Dess-Li/PopupDatePicker/blob/master/Example.gif" />
</p>
<hr>


## Installation

### CocoaPods ([What is that?](https://cocoapods.org/about))
1. Add `pod 'PopupDatePicker'` to your `Podfile`;
2. Then run `pod update` in Terminal;
3. Re-open your project using `.xcworkspace`, put `import PopupDatePicker` in the swift files you plan;
4. Rebuild and enjoy.

## Usage
Firstly, import `PopupDatePicker`.

```swift
import PopupDatePicker
```
### Initialization

```Swift
let datePicker = PopupDatePicker.init(currentDate: nil, minLimitDate: Date(), maxLimitDate: nil, dpShowType: "yyyy-MM-dd", wildcardArray: nil, wildcardDefaults: nil) {_,_ in }
datePicker.show()
```

```
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
```



## Contact Author

Feel free to send pull requests or propose changes.

Email: [li@dess.xyz](mailto:?to=li@dess.xyz)

## License
PopupDatePicker is released under an MIT license. See the [LICENSE](https://raw.githubusercontent.com/vladaverin24/TimelineCards/master/LICENSE.md) file.