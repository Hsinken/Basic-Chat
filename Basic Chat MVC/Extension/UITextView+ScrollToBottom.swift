//
//  UITextView+ScrollToBottom.swift
//  Basic Chat MVC
//
//  Created by wu hsin-hsien on 2023/4/20.
//

import UIKit

extension UITextView {
    func ScrollToBottom() {
        let textCount: Int = text.count
        guard textCount >= 1 else { return }
        scrollRangeToVisible(NSRange(location: textCount - 1, length: 1))
    }
}
