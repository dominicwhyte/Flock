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
    
    struct Constants {
        static let dayOfWeekDateFormat = "EEEE"
        static let fullDateFormat = "yyyy-MM-dd"
    }
    
    static func getDateFromString(date: String) -> Date{
        let dateString = date
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.fullDateFormat
        
        let nsDate = dateFormatter.date(from: dateString)
        return nsDate!
    }
    static func getStringFromDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.fullDateFormat
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
    
    // Gets the current day of the week
    static func getTodayDayOfWeek() -> String {
        let date = Date()
        return self.convertDateToStringByFormat(date: date, dateFormat: Constants.dayOfWeekDateFormat)
    }
    
    // Gets the current date in full format
    static func getTodayFullDate() -> String {
        let date = Date()
        return self.convertDateToStringByFormat(date: date, dateFormat: Constants.fullDateFormat)
    }
    
    static func convertDateToStringByFormat(date : Date, dateFormat : String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let dayOfWeekString = dateFormatter.string(from: date)
        return dayOfWeekString
    }
    
    static func daysUntilPlan(planDate: Date) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dayAndMonth = cal.dateComponents([.day, .month], from: planDate)
        let nextBirthDay = cal.nextDate(after: today, matching: dayAndMonth,
                                        matchingPolicy: .nextTimePreservingSmallerComponents)!
        
        let diff = cal.dateComponents([.day], from: today, to: nextBirthDay)
        return diff.day!
    }
}
