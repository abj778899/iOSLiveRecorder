import SwiftUI

struct RecordingListView: View {
    @EnvironmentObject var viewModel: AnchorViewModel

    var body: some View {
        NavigationView {
            List {
                if viewModel.recordings.isEmpty {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "record.circle")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("当前没有录制任务")
                                    .foregroundColor(.gray)
                                Text("主播上线后会自动开始录制")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 40)
                    }
                } else {
                    ForEach(viewModel.recordings) { task in
                        RecordingRow(task: task)
                    }
                }
            }
            .navigationTitle("录制中")
            .onAppear {
                viewModel.updateRecordings()
            }
        }
    }
}

struct RecordingRow: View {
    @EnvironmentObject var viewModel: AnchorViewModel
    let task: RecordingTask
    @State private var elapsedTime = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.anchorName)
                    .font(.headline)
                HStack {
                    Text("\(task.platform) · \(task.quality)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(elapsedTime)
                        .font(.caption)
                        .foregroundColor(.red)
                        .monospacedDigit()
                }
                Text(task.fileName)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            Spacer()
            Button(action: {
                viewModel.stopRecording(task: task)
            }) {
                Image(systemName: "stop.circle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
        .onReceive(timer) { _ in
            let elapsed = Date().timeIntervalSince(task.startTime)
            let minutes = Int(elapsed) / 60
            let seconds = Int(elapsed) % 60
            elapsedTime = String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
