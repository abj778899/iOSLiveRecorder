import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AnchorViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            AnchorListView()
                .tabItem {
                    Image(systemName: "video.fill")
                    Text("主播监控")
                }
                .tag(0)

            RecordingListView()
                .tabItem {
                    Image(systemName: "record.circle")
                    Text("录制中")
                }
                .tag(1)

            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("录制文件")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("设置")
                }
                .tag(3)
        }
        .sheet(isPresented: $viewModel.showAddAnchor) {
            AddAnchorView()
        }
    }
}
