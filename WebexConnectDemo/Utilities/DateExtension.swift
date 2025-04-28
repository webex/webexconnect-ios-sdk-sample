//
//  DateExtension.swift
//  WebexConnectDemo
//

import Foundation

/// Extension to the `Date` type that provides a method to convert a `Date` instance into a `String` representation using a specified format.
extension Date {
    /// Converts the `Date` instance into a `String` representation using the specified date format.
    /// - Parameter format: The date format string used for the conversion.
    /// - Returns: A string representing the date.
    func stringFromDate(format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
