//
//  StringParamsPairHelper.swift
//  swagr
//
//  Created by peter on 2020/8/26.
//  Copyright © 2020 SWAG. All rights reserved.
//

import Foundation

public enum StringParams: String, CaseIterable {
    case username = "{username}"
}

@objcMembers
public class StringParamsPairHelper: NSObject {
    private static let regex = try! NSRegularExpression(pattern:"[\\{][a-zA-Z0-9]*[\\}]", options: [])
    
    public class func replacement(_ string: String ,params: [String: String]) -> String {
        var resultString = string
        for key in params.keys {
            if let value = params[key] {
                resultString = resultString.replacingOccurrences(of: key, with: value)
            }
        }
        return resultString
    }
    
    public class func paramsRangesFromString(_ string: String) -> [NSRange] {
        let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
        let results = matches.compactMap { (textCheckingResult) -> NSRange? in
            let range = textCheckingResult.range(at: 0)
            let param = (string as NSString).substring(with: range)
            return StringParams(rawValue: param) != nil ? range : nil

        }
        return results
    }
    public class func intersection(_ changeRange: NSRange, in text: String) -> NSRange? {
        let ranges = StringParamsPairHelper.paramsRangesFromString(text)

        for range in ranges {
            if NSIntersectionRange(range, changeRange).location > 0 {
                return range
            }
        }
        return nil
    }

    public class func isLegacy(string: String) -> Bool {
        string.contains("%@")
    }
    
    public class func forceConvert(legacy: String, params: [String]) -> String {
        let regex = try! NSRegularExpression(pattern:"%@", options: [])
        let matches = regex.matches(in: legacy, options: [], range: NSRange(location: 0, length: legacy.utf16.count))
        var resultString = legacy
        for (index, key) in params.enumerated() {
            if index < matches.count {
                let range = matches[index].range

                let start = resultString.index(resultString.startIndex, offsetBy: range.lowerBound)
                let end   = resultString.index(start, offsetBy: range.length)
                resultString.replaceSubrange(start ..< end, with: key)
            }
        }
        return resultString
    }

    public class func hightlightParams(attributedString: NSAttributedString, color: UIColor) -> NSAttributedString {
        let attString = NSMutableAttributedString(attributedString: attributedString)
        
        var highlightAttrs: [NSAttributedString.Key: Any] = [:]
        highlightAttrs[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 14)
        highlightAttrs[NSAttributedString.Key.foregroundColor] = color
        
        let string = attributedString.string
        let utf16 = string.utf16
        
        for stringToFind in StringParams.allCases {
            var nextStartIndex = string.startIndex
        
            while let range = string.range(of: stringToFind.rawValue, options: [.literal], range: nextStartIndex..<string.endIndex) {
        
                let from = range.lowerBound.samePosition(in: utf16)
                let start = utf16.distance(from: utf16.startIndex, to: from!)
                let length = utf16.distance(from: from!, to: range.upperBound.samePosition(in: utf16)!)
        
                attString.setAttributes(highlightAttrs, range: NSMakeRange(start, length))
                nextStartIndex = range.upperBound
            }
        }

        return attString
    }
}
