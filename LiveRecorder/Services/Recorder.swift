import Foundation
import AVFoundation
import UIKit

class Recorder: NSObject {
    static let shared = Recorder()
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private var fileHandles: [String: FileHandle] = [:]
    private var recordingInfo: [String: RecordingTask] = [:]

    private override init() {
        super.init()
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let recordingsDir = paths[0].appendingPathComponent("Recordings", isDirectory: true)
        if !FileManager.default.fileExists(atPath: recordingsDir.path) {
            try? FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)
        }
        return recordingsDir
    }

    func startRecording(anchor: Anchor, streamUrl: String, quality: String) -> RecordingTask? {
        let taskId = "\(anchor.platform)_\(anchor.roomId)_\(Int(Date().timeIntervalSince1970))"
        let safeName = anchor.anchorName.replacingOccurrences(of: "[\\\\/:*?\"<>|]", with: "_", options: .regularExpression)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let fileName = "\(safeName)_\(dateFormatter.string(from: Date()))_\(quality).flv"
        let filePath = getDocumentsDirectory().appendingPathComponent(fileName)

        FileManager.default.createFile(atPath: filePath.path, contents: nil)

        guard let fileHandle = try? FileHandle(forWritingTo: filePath) else {
            return nil
        }

        fileHandles[taskId] = fileHandle

        let task = RecordingTask(
            taskId: taskId,
            anchorName: anchor.anchorName,
            platform: anchor.platform,
            quality: quality,
            startTime: Date(),
            fileName: fileName
        )
        recordingInfo[taskId] = task

        // 使用URLSession下载流
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        guard let url = URL(string: streamUrl) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        if anchor.platform == "抖音" {
            request.setValue("https://www.douyin.com/", forHTTPHeaderField: "Referer")
        } else if anchor.platform == "快手" {
            request.setValue("https://www.kuaishou.com/", forHTTPHeaderField: "Referer")
        } else if anchor.platform == "B站" {
            request.setValue("https://www.bilibili.com/", forHTTPHeaderField: "Referer")
        }

        let downloadTask = session.dataTask(with: request)
        downloadTasks[taskId] = downloadTask
        downloadTask.resume()

        // 开始后台任务
        UIApplication.shared.beginBackgroundTask(withName: "Recording_\(taskId)") { _ in }

        return task
    }

    func stopRecording(taskId: String) {
        if let task = downloadTasks[taskId] {
            task.cancel()
            downloadTasks.removeValue(forKey: taskId)
        }

        if let fileHandle = fileHandles[taskId] {
            try? fileHandle.close()
            fileHandles.removeValue(forKey: taskId)
        }

        recordingInfo.removeValue(forKey: taskId)
    }

    func getRecordingTasks() -> [RecordingTask] {
        return Array(recordingInfo.values)
    }

    func getRecordingsList() -> [URL] {
        let dir = getDocumentsDirectory()
        if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            return files.sorted { $0.path > $1.path }
        }
        return []
    }

    func deleteRecording(fileName: String) {
        let filePath = getDocumentsDirectory().appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: filePath)
    }
}

extension Recorder: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // 找到对应的taskId
        for (taskId, task) in downloadTasks {
            if task == dataTask {
                if let fileHandle = fileHandles[taskId] {
                    fileHandle.write(data)
                }
                break
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // 录制结束
        for (taskId, downloadTask) in downloadTasks {
            if downloadTask == task {
                if let fileHandle = fileHandles[taskId] {
                    try? fileHandle.close()
                    fileHandles.removeValue(forKey: taskId)
                }
                downloadTasks.removeValue(forKey: taskId)
                recordingInfo.removeValue(forKey: taskId)
                break
            }
        }
    }
}
