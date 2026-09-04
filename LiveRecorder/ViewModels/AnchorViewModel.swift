import Foundation
import Combine

class AnchorViewModel: ObservableObject {
    @Published var anchors: [Anchor] = []
    @Published var recordings: [RecordingTask] = []
    @Published var isMonitoring = false
    @Published var showAddAnchor = false
    @Published var selectedTab = 0

    private var monitorTimer: Timer?
    private let parser = StreamParser.shared
    private let recorder = Recorder.shared

    init() {
        loadAnchors()
        updateRecordings()
    }

    // MARK: - 主播管理
    func addAnchor(platform: String, roomId: String, anchorName: String = "", quality: String = "原画", autoRecord: Bool = true) {
        let url = parser.buildUrl(platform: platform, roomId: roomId)
        let anchor = Anchor(
            url: url,
            platform: platform,
            roomId: roomId,
            anchorName: anchorName.isEmpty ? "\(platform)主播_\(roomId)" : anchorName,
            autoRecord: autoRecord,
            quality: quality
        )
        anchors.append(anchor)
        saveAnchors()

        // 立即检测一次
        checkAnchor(anchor: anchor)
    }

    func removeAnchor(anchor: Anchor) {
        anchors.removeAll { $0.id == anchor.id }
        saveAnchors()
    }

    // MARK: - 监控
    func startMonitoring() {
        isMonitoring = true
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkAllAnchors()
        }
        checkAllAnchors()
    }

    func stopMonitoring() {
        isMonitoring = false
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    func checkAllAnchors() {
        for anchor in anchors {
            checkAnchor(anchor: anchor)
        }
    }

    func checkAnchor(anchor: Anchor) {
        parser.parse(url: anchor.url) { [weak self] info in
            DispatchQueue.main.async {
                if let info = info {
                    if let index = self?.anchors.firstIndex(where: { $0.id == anchor.id }) {
                        self?.anchors[index].isLiving = info.isLiving
                        if !info.anchorName.isEmpty && info.anchorName != "未知主播" {
                            self?.anchors[index].anchorName = info.anchorName
                        }

                        // 自动录制
                        if info.isLiving && anchor.autoRecord && !self!.isRecording(anchor: anchor) {
                            self?.startRecording(anchor: self!.anchors[index], info: info)
                        }
                    }
                    self?.saveAnchors()
                }
            }
        }
    }

    // MARK: - 录制
    func startRecording(anchor: Anchor, info: StreamInfo? = nil) {
        if isRecording(anchor: anchor) { return }

        if let info = info, !info.bestUrl.isEmpty {
            let quality = anchor.quality
            let streamUrl = info.streamUrls[quality] ?? info.bestUrl
            if let task = recorder.startRecording(anchor: anchor, streamUrl: streamUrl, quality: quality) {
                recordings.append(task)
            }
        } else {
            parser.parse(url: anchor.url) { [weak self] parsedInfo in
                if let parsedInfo = parsedInfo, !parsedInfo.bestUrl.isEmpty {
                    let quality = anchor.quality
                    let streamUrl = parsedInfo.streamUrls[quality] ?? parsedInfo.bestUrl
                    DispatchQueue.main.async {
                        if let task = self?.recorder.startRecording(anchor: anchor, streamUrl: streamUrl, quality: quality) {
                            self?.recordings.append(task)
                        }
                    }
                }
            }
        }
    }

    func stopRecording(task: RecordingTask) {
        recorder.stopRecording(taskId: task.taskId)
        recordings.removeAll { $0.taskId == task.taskId }
        updateRecordings()
    }

    func isRecording(anchor: Anchor) -> Bool {
        return recordings.contains { $0.anchorName == anchor.anchorName && $0.platform == anchor.platform }
    }

    func updateRecordings() {
        recordings = recorder.getRecordingTasks()
    }

    // MARK: - 文件管理
    func getRecordingsList() -> [URL] {
        return recorder.getRecordingsList()
    }

    func deleteRecording(fileName: String) {
        recorder.deleteRecording(fileName: fileName)
    }

    // MARK: - 持久化
    private func saveAnchors() {
        if let encoded = try? JSONEncoder().encode(anchors) {
            UserDefaults.standard.set(encoded, forKey: "anchors")
        }
    }

    private func loadAnchors() {
        if let data = UserDefaults.standard.data(forKey: "anchors"),
           let decoded = try? JSONDecoder().decode([Anchor].self, from: data) {
            anchors = decoded
        }
    }
}
