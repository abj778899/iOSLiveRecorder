import Foundation

class StreamParser {
    static let shared = StreamParser()
    private var session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        ]
        session = URLSession(configuration: config)
    }

    func parse(url: String, completion: @escaping (StreamInfo?) -> Void) {
        if url.contains("douyin.com") {
            parseDouyin(url: url, completion: completion)
        } else if url.contains("kuaishou.com") {
            parseKuaishou(url: url, completion: completion)
        } else if url.contains("bilibili.com") {
            parseBilibili(url: url, completion: completion)
        } else if url.contains("huya.com") {
            parseHuya(url: url, completion: completion)
        } else if url.contains("douyu.com") {
            parseDouyu(url: url, completion: completion)
        } else {
            completion(nil)
        }
    }

    // MARK: - 抖音解析
    func parseDouyin(url: String, completion: @escaping (StreamInfo?) -> Void) {
        var info = StreamInfo()
        info.platform = "抖音"

        // 提取房间号
        if let range = url.range(of: #"live\.douyin\.com/(\d+)"#, options: .regularExpression) {
            let roomId = String(url[range].split(separator: "/").last ?? "")
            info.roomId = roomId
        } else if let range = url.range(of: #"/live/(\d+)"#, options: .regularExpression) {
            let roomId = String(url[range].split(separator: "/").last ?? "")
            info.roomId = roomId
        }

        guard !info.roomId.isEmpty else {
            completion(nil)
            return
        }

        let liveUrl = "https://live.douyin.com/\(info.roomId)"

        // 先访问页面获取cookie
        guard let url = URL(string: liveUrl) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("https://live.douyin.com/", forHTTPHeaderField: "Referer")

        session.dataTask(with: request) { [weak self] _, response, _ in
            // 调用API
            let apiUrl = "https://live.douyin.com/webcast/room/web/enter/?aid=6383&app_name=douyin_web&live_id=1&device_platform=web&language=zh-CN&enter_from=web_live&cookie_enabled=true&screen_width=1920&screen_height=1080&browser_language=zh-CN&browser_platform=Win32&browser_name=Chrome&browser_version=120.0.0.0&web_rid=\(info.roomId)"

            guard let apiURL = URL(string: apiUrl) else {
                completion(nil)
                return
            }

            var apiRequest = URLRequest(url: apiURL)
            apiRequest.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
            apiRequest.setValue(liveUrl, forHTTPHeaderField: "Referer")
            apiRequest.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")

            self?.session.dataTask(with: apiRequest) { data, _, _ in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let dataDict = json["data"] as? [String: Any],
                      let roomArray = dataDict["data"] as? [[String: Any]],
                      let roomData = roomArray.first else {
                    // 即使失败也返回基本信息
                    info.anchorName = "抖音主播_\(info.roomId)"
                    info.isLiving = false
                    completion(info)
                    return
                }

                // 主播信息
                if let owner = roomData["owner"] as? [String: Any] {
                    info.anchorName = owner["nickname"] as? String ?? "未知主播"
                }

                // 直播间标题
                info.roomTitle = roomData["title"] as? String ?? ""

                // 直播状态
                let status = roomData["status"] as? Int ?? 0
                info.isLiving = (status == 2)

                if info.isLiving, let streamUrl = roomData["stream_url"] as? [String: Any] {
                    let qualityMap = [
                        "FULL_HD1": "原画",
                        "HD1": "超清",
                        "SD1": "高清",
                        "SD2": "标清"
                    ]

                    if let flvPull = streamUrl["flv_pull_url"] as? [String: String] {
                        for (key, name) in qualityMap {
                            if let url = flvPull[key] {
                                info.streamUrls[name] = url
                            }
                        }
                    }

                    if let hlsPull = streamUrl["hls_pull_url_map"] as? [String: String] {
                        for (key, name) in qualityMap {
                            if let url = hlsPull[key], info.streamUrls[name] == nil {
                                info.streamUrls[name] = url
                            }
                        }
                    }

                    let qualityOrder = ["原画", "超清", "高清", "标清", "流畅"]
                    for q in qualityOrder {
                        if let url = info.streamUrls[q] {
                            info.bestQuality = q
                            info.bestUrl = url
                            break
                        }
                    }

                    if info.bestUrl.isEmpty, let first = info.streamUrls.first {
                        info.bestQuality = first.key
                        info.bestUrl = first.value
                    }
                }

                completion(info)
            }.resume()
        }.resume()
    }

    // MARK: - 快手解析
    func parseKuaishou(url: String, completion: @escaping (StreamInfo?) -> Void) {
        var info = StreamInfo()
        info.platform = "快手"

        if let range = url.range(of: #"/u/([^/?#]+)"#, options: .regularExpression) {
            let userId = String(url[range].split(separator: "/").last ?? "")
            info.roomId = userId
        }

        guard !info.roomId.isEmpty else {
            completion(nil)
            return
        }

        info.anchorName = "快手主播_\(info.roomId)"
        info.isLiving = false
        completion(info)
    }

    // MARK: - B站解析
    func parseBilibili(url: String, completion: @escaping (StreamInfo?) -> Void) {
        var info = StreamInfo()
        info.platform = "B站"

        if let range = url.range(of: #"/(\d+)"#, options: .regularExpression) {
            let roomId = String(url[range].split(separator: "/").last ?? "")
            info.roomId = roomId
        }

        guard !info.roomId.isEmpty else {
            completion(nil)
            return
        }

        let apiUrl = "https://api.live.bilibili.com/room/v1/Room/get_info?room_id=\(info.roomId)"
        guard let url = URL(string: apiUrl) else {
            completion(nil)
            return
        }

        session.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataDict = json["data"] as? [String: Any] else {
                info.anchorName = "B站主播_\(info.roomId)"
                info.isLiving = false
                completion(info)
                return
            }

            info.roomTitle = dataDict["title"] as? String ?? ""
            info.isLiving = (dataDict["live_status"] as? Int ?? 0) == 1

            if let uid = dataDict["uid"] as? Int {
                let userApi = "https://api.live.bilibili.com/live_user/v1/Master/info?uid=\(uid)"
                if let userUrl = URL(string: userApi) {
                    self.session.dataTask(with: userUrl) { userData, _, _ in
                        if let userData = userData,
                           let userJson = try? JSONSerialization.jsonObject(with: userData) as? [String: Any],
                           let userData = userJson["data"] as? [String: Any],
                           let infoDict = userData["info"] as? [String: Any] {
                            info.anchorName = infoDict["uname"] as? String ?? "未知主播"
                        }
                        completion(info)
                    }.resume()
                } else {
                    completion(info)
                }
            } else {
                completion(info)
            }
        }.resume()
    }

    // MARK: - 虎牙解析
    func parseHuya(url: String, completion: @escaping (StreamInfo?) -> Void) {
        var info = StreamInfo()
        info.platform = "虎牙"

        if let range = url.range(of: #"/(\d+)"#, options: .regularExpression) {
            let roomId = String(url[range].split(separator: "/").last ?? "")
            info.roomId = roomId
        }

        guard !info.roomId.isEmpty else {
            completion(nil)
            return
        }

        info.anchorName = "虎牙主播_\(info.roomId)"
        info.isLiving = false
        completion(info)
    }

    // MARK: - 斗鱼解析
    func parseDouyu(url: String, completion: @escaping (StreamInfo?) -> Void) {
        var info = StreamInfo()
        info.platform = "斗鱼"

        if let range = url.range(of: #"/(\d+)"#, options: .regularExpression) {
            let roomId = String(url[range].split(separator: "/").last ?? "")
            info.roomId = roomId
        }

        guard !info.roomId.isEmpty else {
            completion(nil)
            return
        }

        info.anchorName = "斗鱼主播_\(info.roomId)"
        info.isLiving = false
        completion(info)
    }

    // 根据平台和房间号构造URL
    func buildUrl(platform: String, roomId: String) -> String {
        switch platform {
        case "抖音":
            return "https://live.douyin.com/\(roomId)"
        case "快手":
            return "https://live.kuaishou.com/u/\(roomId)"
        case "B站":
            return "https://live.bilibili.com/\(roomId)"
        case "虎牙":
            return "https://www.huya.com/\(roomId)"
        case "斗鱼":
            return "https://www.douyu.com/\(roomId)"
        default:
            return roomId
        }
    }
}
