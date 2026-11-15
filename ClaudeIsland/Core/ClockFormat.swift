//
//  ClockFormat.swift
//  ClaudeIsland
//
//  12h / 24h time display, switched by the "24-hour time" setting (UserDefaults key `use24HourTime`).
//

import Foundation

enum ClockFormat {
    static let defaultsKey = "use24HourTime"

    private static let formatters: [String: DateFormatter] = {
        var out: [String: DateFormatter] = [:]
        for format in ["HH:mm", "EEE HH:mm", "h:mm a", "EEE h:mm a"] {
            let f = DateFormatter()
            f.dateFormat = format
            out[format] = f
        }
        return out
    }()

    static var use24Hour: Bool {
        UserDefaults.standard.object(forKey: defaultsKey) as? Bool ?? true
    }

    /// "14:00" or "2:00 PM"; includes the weekday ("Thu 14:00") when the date is not today.
    static func string(_ date: Date, use24Hour: Bool = ClockFormat.use24Hour) -> String {
        let weekday = !Calendar.current.isDateInToday(date)
        let format = (weekday ? "EEE " : "") + (use24Hour ? "HH:mm" : "h:mm a")
        return formatters[format]?.string(from: date) ?? ""
    }
}
