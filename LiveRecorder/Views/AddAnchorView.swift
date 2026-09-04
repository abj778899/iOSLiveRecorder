import SwiftUI

struct AddAnchorView: View {
    @EnvironmentObject var viewModel: AnchorViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedPlatform = "抖音"
    @State private var roomId = ""
    @State private var anchorName = ""
    @State private var quality = "原画"
    @State private var autoRecord = true
    @State private var isParsing = false
    @State private var parseResult = ""

    let platforms = ["抖音", "快手", "B站", "虎牙", "斗鱼"]
    let qualities = ["原画", "超清", "高清", "标清"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("平台选择")) {
                    Picker("直播平台", selection: $selectedPlatform) {
                        ForEach(platforms, id: \.self) { platform in
                            Text(platform).tag(platform)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("主播信息")) {
                    TextField("输入主播号/房间号", text: $roomId)
                        .keyboardType(.numberPad)
                    TextField("主播备注（留空自动获取）", text: $anchorName)
                }

                Section(header: Text("录制设置")) {
                    Picker("录制画质", selection: $quality) {
                        ForEach(qualities, id: \.self) { q in
                            Text(q).tag(q)
                        }
                    }
                    Toggle("上线自动录制", isOn: $autoRecord)
                }

                if !parseResult.isEmpty {
                    Section {
                        Text(parseResult)
                            .foregroundColor(.gray)
                    }
                }

                Section {
                    Button(action: addAnchor) {
                        HStack {
                            Spacer()
                            if isParsing {
                                ProgressView()
                            } else {
                                Text("添加主播")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(roomId.isEmpty || isParsing)
                }
            }
            .navigationTitle("添加主播")
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private func addAnchor() {
        isParsing = true
        parseResult = "正在解析主播信息..."

        let parser = StreamParser.shared
        let url = parser.buildUrl(platform: selectedPlatform, roomId: roomId)

        parser.parse(url: url) { info in
            DispatchQueue.main.async {
                isParsing = false
                if let info = info {
                    let name = anchorName.isEmpty ? info.anchorName : anchorName
                    viewModel.addAnchor(
                        platform: selectedPlatform,
                        roomId: roomId,
                        anchorName: name,
                        quality: quality,
                        autoRecord: autoRecord
                    )
                    parseResult = "添加成功：\(name)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        presentationMode.wrappedValue.dismiss()
                    }
                } else {
                    parseResult = "解析失败，但已添加主播，将在监控时自动获取信息"
                    viewModel.addAnchor(
                        platform: selectedPlatform,
                        roomId: roomId,
                        anchorName: anchorName.isEmpty ? "\(selectedPlatform)主播_\(roomId)" : anchorName,
                        quality: quality,
                        autoRecord: autoRecord
                    )
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
