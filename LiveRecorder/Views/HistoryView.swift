import SwiftUI
import AVKit

struct HistoryView: View {
    @EnvironmentObject var viewModel: AnchorViewModel
    @State private var recordings: [URL] = []
    @State private var selectedVideo: URL?
    @State private var showVideoPlayer = false

    var body: some View {
        NavigationView {
            List {
                if recordings.isEmpty {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "folder")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("还没有录制文件")
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 40)
                    }
                } else {
                    ForEach(recordings, id: \.self) { file in
                        HistoryRow(file: file, onPlay: {
                            selectedVideo = file
                            showVideoPlayer = true
                        }, onDelete: {
                            viewModel.deleteRecording(fileName: file.lastPathComponent)
                            loadRecordings()
                        })
                    }
                }
            }
            .navigationTitle("录制文件")
            .onAppear {
                loadRecordings()
            }
            .sheet(isPresented: $showVideoPlayer) {
                if let video = selectedVideo {
                    VideoPlayer(player: AVPlayer(url: video))
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
    }

    private func loadRecordings() {
        recordings = viewModel.getRecordingsList()
    }
}

struct HistoryRow: View {
    let file: URL
    let onPlay: () -> Void
    let onDelete: () -> Void
    @State private var fileSize = ""

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(file.lastPathComponent)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(fileSize)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Button(action: onPlay) {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
               let size = attributes[.size] as? Int {
                fileSize = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            }
        }
    }
}
