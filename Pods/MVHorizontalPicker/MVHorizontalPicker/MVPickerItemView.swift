/*
MVHorizontalPicker - Copyright (c) 2016 Andrea Bizzotto bizz84@gmail.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import UIKit

@objc class MVPickerItemView: UIView {

    let label: UILabel
    
    var selected: Bool = false {
        didSet {
            updateTextColor(selected: selected)
        }
    }
    
    override var tintColor: UIColor! {
        didSet {
            updateTextColor(selected: selected)
        }
    }
    
    var font: UIFont? {
        get {
            return label.font
        }
        set {
            label.font = newValue
        }
    }

    init(text: String, font: UIFont?) {
        
        self.label = UILabel()
        
        super.init(frame: CGRect.zero)
        addLabel(label)
        label.text = text
        label.font = font
        label.textAlignment = NSTextAlignment.center
        label.lineBreakMode = .byTruncatingMiddle
        
        updateTextColor(selected: false)
    }
    
    func addLabel(_ label: UILabel) {
        self.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraint(label.makeEqualityConstraint(attribute: .leading, toView: self))
        self.addConstraint(label.makeEqualityConstraint(attribute: .trailing, toView: self))
        self.addConstraint(label.makeEqualityConstraint(attribute: .centerY, toView: self))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    func updateTextColor(selected: Bool) {
        
        let alpha: CGFloat = selected ? 1.0 : 0.5
        self.label.textColor = tintColor.withAlphaComponent(alpha)
    }
}
