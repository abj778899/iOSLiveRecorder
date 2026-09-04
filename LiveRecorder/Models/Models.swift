import Foundation

struct StreamInfo: Codable {
    var platform: String = ""
    var roomId: String = ""
    var anchorName: String = ""
    var roomTitle: String = ""
    var isLiving: Bool = false
    var streamUrls: [String: String] = [:]
    var bestQuality: String = ""
    var bestUrl: String = ""
}

struct Anchor: Codable, Identifiable {
    var id = UUID()
    var url: String
    var platform: String
    var roomId: String
    var anchorName: String
    var autoRecord: Bool = true
    var quality: String = "原画"
    var addTime: Date = Date()
    var isLiving: Bool = false
}

struct RecordingTask: Codable, Identifiable {
    var id = UUID()
    var taskId: String
    var anchorName: String
    var platform: String
    var quality: String
    var startTime: Date
    var fileName: String
    var isRecording: Bool = true
}

struct HistoryItem: Codable, Identifiable {
    var id = UUID()
    var anchorName: String
    var platform: String
    var quality: String
    var startTime: Date
    var duration: String
    var fileSize: String
    var status: String
    var fileName: String
}
