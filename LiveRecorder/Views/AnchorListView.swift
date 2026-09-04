import SwiftUI

struct AnchorListView: View {
    @EnvironmentObject var viewModel: AnchorViewModel

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("监控主播: \(viewModel.anchors.count)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("直播中: \(viewModel.anchors.filter { $0.isLiving }.count)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        if viewModel.isMonitoring {
                            Button("停止监控") {
                                viewModel.stopMonitoring()
                            }
                            .foregroundColor(.red)
                        } else {
                            Button("开始监控") {
                                viewModel.startMonitoring()
                            }
                            .foregroundColor(.green)
                        }
                    }
                }

                ForEach(viewModel.anchors) { anchor in
                    AnchorRow(anchor: anchor)
                }
                .onDelete(perform: deleteAnchor)
            }
            .navigationTitle("主播监控")
            .navigationBarItems(trailing: Button(action: {
                viewModel.showAddAnchor = true
            }) {
                Image(systemName: "plus")
            })
            .overlay(
                VStack {
                    if viewModel.anchors.isEmpty {
                        Text("还没有添加主播")
                            .foregroundColor(.gray)
                        Text("点击右上角 + 添加主播")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            )
        }
    }

    private func deleteAnchor(at offsets: IndexSet) {
        offsets.forEach { index in
            viewModel.removeAnchor(anchor: viewModel.anchors[index])
        }
    }
}

struct AnchorRow: View {
    @EnvironmentObject var viewModel: AnchorViewModel
    let anchor: Anchor

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(anchor.anchorName)
                        .font(.headline)
                    Spacer()
                    statusBadge
                }
                Text("\(anchor.platform) · 房间号: \(anchor.roomId)")
                    .font(.caption)
                    .foregroundColor(.gray)
                HStack {
                    Text("画质: \(anchor.quality)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(anchor.autoRecord ? "自动录制" : "手动录制")
                        .font(.caption2)
                        .foregroundColor(anchor.autoRecord ? .green : .orange)
                }
            }

            if anchor.isLiving && !viewModel.isRecording(anchor: anchor) {
                Button(action: {
                    viewModel.startRecording(anchor: anchor)
                }) {
                    Image(systemName: "record.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                }
            } else if viewModel.isRecording(anchor: anchor) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundColor(.red)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        Group {
            if anchor.isLiving {
                Text("直播中")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            } else {
                Text("未开播")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.gray)
                    .cornerRadius(4)
            }
        }
    }
}
