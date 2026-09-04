import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: AnchorViewModel
    @State private var showAbout = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("监控设置")) {
                    HStack {
                        Text("监控状态")
                        Spacer()
                        Text(viewModel.isMonitoring ? "运行中" : "已停止")
                            .foregroundColor(viewModel.isMonitoring ? .green : .gray)
                    }
                    Button(action: {
                        if viewModel.isMonitoring {
                            viewModel.stopMonitoring()
                        } else {
                            viewModel.startMonitoring()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text(viewModel.isMonitoring ? "停止监控" : "开始监控")
                                .foregroundColor(viewModel.isMonitoring ? .red : .green)
                            Spacer()
                        }
                    }
                    Button(action: {
                        viewModel.checkAllAnchors()
                    }) {
                        HStack {
                            Spacer()
                            Text("立即检测所有主播")
                                .foregroundColor(.blue)
                            Spacer()
                        }
                    }
                }

                Section(header: Text("统计信息")) {
                    HStack {
                        Text("监控主播数")
                        Spacer()
                        Text("\(viewModel.anchors.count)")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("直播中")
                        Spacer()
                        Text("\(viewModel.anchors.filter { $0.isLiving }.count)")
                            .foregroundColor(.green)
                    }
                    HStack {
                        Text("录制中")
                        Spacer()
                        Text("\(viewModel.recordings.count)")
                            .foregroundColor(.red)
                    }
                }

                Section(header: Text("录制文件")) {
                    Button(action: {
                        if let dir = Recorder.shared.getDocumentsDirectory() as URL? {
                            UIApplication.shared.open(dir)
                        }
                    }) {
                        HStack {
                            Text("打开录制文件夹")
                            Spacer()
                            Image(systemName: "folder")
                                .foregroundColor(.gray)
                        }
                    }
                }

                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("支持平台")
                        Spacer()
                        Text("抖音/快手/B站/虎牙/斗鱼")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}
