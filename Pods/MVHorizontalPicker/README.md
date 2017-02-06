# MVHorizontalPicker

MVHorizontalPicker is a simple scrollable horizontal control, alternative to UISegmentedControl.

[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat
            )](http://mit-license.org)
[![Platform](https://img.shields.io/badge/platform-ios%20-lightgrey.svg?style=flat
             )](https://developer.apple.com/resources/)
[![Language](http://img.shields.io/badge/language-swift-orange.svg?style=flat
             )](https://developer.apple.com/swift)
[![Issues](https://img.shields.io/github/issues/bizz84/MVHorizontalPicker.svg?style=flat
           )](https://github.com/bizz84/MVHorizontalPicker/issues)
[![Cocoapod](http://img.shields.io/cocoapods/v/MVHorizontalPicker.svg?style=flat)](http://cocoadocs.org/docsets/MVHorizontalPicker/)

## Preview

![MVHorizontalPicker preview](https://github.com/bizz84/MVHorizontalPicker/raw/master/preview.gif "MVHorizontalPicker preview")

## Motivation

While `UISegmentedControl` is a good way of selecting amongst a few options, generally it has only space to show up to 5 values on iPhone portrait mode.
For larger option sets `UIPickerView` can be the right choice, however it also takes up more screen space.

`MVHorizontalPicker` is the ideal UI control for choosing an item from up to a dozen possible values.

## Usage

```swift
class ViewController: UIViewController {

    @IBOutlet var picker: MVHorizontalPicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        picker.titles = [ "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" ]
    }

    @IBAction func pickerValueChanged(sender: AnyObject) { // Value Changed event

        let title = picker.titles[picker.selectedItemIndex]
        print("selected: \(title)")
    }
}
```

### Features

* Register to `UIControlEvents.ValueChanged` to check when the picker value has changed (same target/selector method used by `UISegmentedControl`).
* `@IBDesignable` properties for easier configuration in Interface builder
* Seamless integration in existing storyboards: Just drag a UIView, set the class type to `MVHorizontalPicker` and configure the presentation properties as needed.

### Customisation

`MVHorizontalPicker` aims to be customisable. The following UI properties are currently supported:

* tintColor
* font
* itemWidth
* cornerRadius (IBInspectable)
* borderWidth (IBInspectable)

### Auto-layout

`MVHorizontalPicker` is entirely built using auto-layout. As a result, it can be easily stretched to fit various widths and heights.


## Installation

MVHorizontalPicker can be installed as a Cocoapod and builds as a Swift framework. To install, include this in your Podfile.

```
use_frameworks!

pod 'MVHorizontalPicker'
```

Once installed, just import MVHorizontalPicker in your classes and you're good to go.

## Sample Code

A sample demo project is included to show how to use `MVHorizontalPicker`.

## License

Copyright (c) 2016 Andrea Bizzotto bizz84@gmail.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
