import SwiftUI
import WidgetKit

struct WidgetClass: Codable, Identifiable, Hashable {
    let id: String
    let subject: String
    let room: String?
    let date: String
    let start: Int
    let end: Int
    let exam: Bool
    let timeRange: String
}

struct WidgetSnapshot: Codable {
    let signedIn: Bool
    let loaded: Bool?
    let weekStart: String
    let items: [WidgetClass]
}

enum SharedStore {
    static let appGroup = "group.com.example.cmccheckin" // đổi cho khớp entitlement
    static let key = "widget_snapshot"
    static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    static func read() -> WidgetSnapshot? {
        guard let text = defaults?.string(forKey: key),
              let data = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}

private struct CheckInTimelineEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

private struct CheckInProvider: TimelineProvider {
    func placeholder(in context: Context) -> CheckInTimelineEntry {
        CheckInTimelineEntry(date: Date(), snapshot: nil)
    }
    func getSnapshot(in context: Context, completion: @escaping (CheckInTimelineEntry) -> Void) {
        completion(CheckInTimelineEntry(date: Date(), snapshot: SharedStore.read()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CheckInTimelineEntry>) -> Void) {
        let now = Date()
        let entry = CheckInTimelineEntry(date: now, snapshot: SharedStore.read())
        completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(15 * 60))))
    }
}

private enum WidgetSelection {
    static func todayKey(_ now: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: now)
    }
    static func weekKey(_ now: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        let monday = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        return todayKey(monday)
    }
    static func currentOrNext(_ items: [WidgetClass], now: Date) -> (WidgetClass?, Bool) {
        let today = todayKey(now)
        let parts = Calendar.current.dateComponents([.hour, .minute], from: now)
        let minute = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        let classes = items.filter { !$0.exam && $0.date == today }
        let current = classes.filter { $0.start - 15 <= minute && minute < $0.end }
            .sorted { $0.start > $1.start }.first
        if let current { return (current, true) }
        let next = classes.filter { $0.start - 15 > minute }
            .sorted { $0.start < $1.start }.first
        return (next, false)
    }
}

private struct CheckInWidgetView: View {
    let entry: CheckInTimelineEntry

    var body: some View {
        let snap = entry.snapshot
        let valid = snap?.weekStart == WidgetSelection.weekKey(entry.date)
        let selection = (snap != nil && valid)
            ? WidgetSelection.currentOrNext(snap!.items, now: entry.date)
            : (nil, false)
        let selected = selection.0
        let ongoing = selection.1

        let label: String = {
            if snap?.signedIn != true { return "CMC Check-in" }
            if valid != true || snap?.loaded == false { return "Attendance" }
            return ongoing ? "Now" : (selected == nil ? "Attendance" : "Next")
        }()
        let headline: String = {
            if snap?.signedIn != true { return "Sign in to view schedule" }
            if valid != true || snap?.loaded == false { return "Schedule not loaded yet" }
            return selected?.subject ?? "No more classes today"
        }()
        let target = URL(string: ongoing ? "cmccheckin://checkin" : "cmccheckin://open")!

        Link(destination: target) {
            VStack(alignment: .leading, spacing: 8) {
                Text(label).font(.caption).fontWeight(.semibold)
                Text(headline).font(.headline).lineLimit(2)
                if let selected {
                    Text([selected.timeRange, selected.room].compactMap { $0 }.joined(separator: " · "))
                        .font(.caption).lineLimit(2)
                }
                Spacer(minLength: 2)
                Text(ongoing ? "Enter keyword" : "Open schedule")
                    .font(.caption).fontWeight(.medium)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .containerBackground(for: .widget) { Color(uiColor: .secondarySystemBackground) }
    }
}

@main
struct CheckInWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CheckInWidget", provider: CheckInProvider()) { entry in
            CheckInWidgetView(entry: entry)
        }
        .configurationDisplayName("CMC Check-in")
        .description("Current or next class and a shortcut to enter the attendance keyword.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
