//
//  UITextView+Hyperlink.swift
//  Basic Chat MVC
//
//  Created by wu hsin-hsien on 2023/4/22.
//

import UIKit

let kUITextViewHyperLinkFont = UIFont.systemFont(ofSize: 17)
let kUITextViewHyperTextColor = UIColor.systemGreen
let kUITextViewHyperLinkColor = UIColor.link

extension UITextView {
    func addHyperLinksToText(originalText: String, hyperLinks: [String: String]) {
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        let attributedOriginalText = NSMutableAttributedString(string: originalText)
        for (hyperLink, urlString) in hyperLinks {
            let linkRange = attributedOriginalText.mutableString.range(of: hyperLink)
            let fullRange = NSRange(location: 0, length: attributedOriginalText.length)
            attributedOriginalText.addAttribute(NSAttributedString.Key.link, value: urlString, range: linkRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: fullRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.foregroundColor, value: kUITextViewHyperTextColor, range: fullRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.font, value: kUITextViewHyperLinkFont, range: fullRange)
        }
        
        self.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor: kUITextViewHyperLinkColor,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
        
        if let attrStr = self.attributedText {
            let newMutableString = attrStr.mutableCopy() as! NSMutableAttributedString
            newMutableString.append(attributedOriginalText)
            self.attributedText = newMutableString
        } else {
            self.attributedText = attributedOriginalText
        }
        
    }
}
