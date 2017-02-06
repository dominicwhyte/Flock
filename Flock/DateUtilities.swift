//
//  DateUtilities.swift
//  Flock
//
//  Created by Dominic Whyte on 05/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import Foundation

// Convert date to string in the format "yyyy-MM-dd"
class DateUtilities {
    static func getDateFromString(date: String) -> Date{
        let dateString = date
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let nsDate = dateFormatter.date(from: dateString)
        return nsDate!
    }
    static func getStringFromDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
}
