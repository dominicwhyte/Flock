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
        static let uiDisplayFormat = "EEEE, MMMM d"
        static let NUMBER_OF_DAYS_TO_DISPLAY = 7
        static let START_NIGHT_OUT_TIME : Double = 22.0
        static let END_NIGHT_OUT_TIME : Double = 6.0
    }
    
    static func isValidNightOutTime(startTime : Double, endTime : Double) -> Bool {
        let date = Date()
        let calendar = Calendar.current
        
        let hour = Double(calendar.component(.hour, from: date))
        return (hour >= startTime || hour < endTime)
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
    static func getHourFromDouble(hourDouble: Double) -> String {
        var hourString: String = ""
        // First figure out the base hour
        
        if(Int(hourDouble) == 0 || Int(hourDouble) == 12) {
            hourString = "12"
        } else {
            hourString = String(Int(floor(hourDouble)) % 12)
        }
        // Get remaidner
        if(floor(hourDouble) != hourDouble) {
            let remainder = hourDouble - floor(hourDouble)
            hourString += ":"
            hourString += String(Int(remainder*60))
        }
        
        // determine am/pm
        if(hourDouble < 12) {
            hourString += "am"
        } else {
            hourString += "pm"
        }
        
        return hourString
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
        let calendar = NSCalendar.current
        
        // Replace the hour (time) of both dates with 00:00
        let date1 = calendar.startOfDay(for: Date())
        let date2 = calendar.startOfDay(for: planDate)

        let components = calendar.dateComponents([.day], from: date1, to: date2)
        return components.day!
    }
    
    static func isDateBeforeToday(date: Date) -> Bool {
        return (self.daysUntilPlan(planDate: date) < 0)
    }
    
    static func isValidTimeFrame(dayDiff: Int) -> Bool {
        return (dayDiff >= 0 && dayDiff < Constants.NUMBER_OF_DAYS_TO_DISPLAY)
    }
}
