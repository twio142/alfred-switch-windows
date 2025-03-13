import Foundation

extension RunningApp: AlfredItem {
  var title: String { return name }
  var subtitle: String { return fullPath }
  var arg: String { return fullPath }
  var variables: [String: Any] { return ["bundleId": bundleId] }
  var icon: [String: Any] { return ["path": fullPath, "type": "fileicon"] }
  var type: String? { return "file" }
  var text: [String: Any]? { return nil }
  var quicklookurl: String? { return nil }
}

extension WindowInfoDict: AlfredItem {
  var title: String { return name }
  var subtitle: String { return processName }
  var arg: String { return "" }
  var variables: [String: Any] { return ["bundleId": bundleId, "windowId": number] }
  var icon: [String: Any] { return ["path": fullPath, "type": "fileicon"] }
  var type: String? { return nil }
  var text: [String: Any]? { return nil }
  var quicklookurl: String? { return nil }
}

extension BrowserTab: AlfredItem {
  var title: String { return "\(location == "pinned" ? "📌 " : (location == "topApp" ? "🔝 " : ""))\(tabTitle)" }
  var arg: String { return "[\(tabTitle)](\(url.replacingOccurrences(of: "chrome-extension://[a-z]+/suspended.html#.+?&uri=", with: "", options: [.regularExpression])))" } // get original url before chrome extension `tab suspender`
  var subtitle: String { return "\(url)" }
  var variables: [String: Any] { return ["tabIndex": tabIndex, "windowIndex": windowIndex, "bundleId": bundleId, "tabId": id] }
  var icon: [String: Any] { if let iconPath = iconPath { return ["path": iconPath] } else { return ["path": fullPath, "type": "fileicon"] } }
  var type: String? { return "file:skipcheck" }
  var text: [String: Any]? { return ["copy": url] }
  var quicklookurl: String? { return url }
}
