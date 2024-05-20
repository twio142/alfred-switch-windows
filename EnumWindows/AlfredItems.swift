import Foundation

extension WindowInfoDict : AlfredItem {
    var title : String { return self.name };
    var subtitle : String { return self.processName };
    var arg: String { return "" };
    var variables : [String : Any] { return ["bundleId":self.bundleId, "windowId":self.number] };
    var icon: [String : Any] { return ["path": self.fullPath, "type": "fileicon"] };
    var type: String? { return nil };
    var text: [String : Any]? { return nil };
    var quicklookurl: String? { return nil };
}

extension BrowserTab : AlfredItem {
    var title: String { return "\(self.location == "pinned" ? "📌 " : (self.location == "topApp" ? "🔝 " : ""))\(self.tabTitle)" };
    var arg: String { return "[\(self.tabTitle)](\(self.url.replacingOccurrences(of: "chrome-extension://[a-z]+/suspended.html#.+?&uri=", with: "", options: [.regularExpression])))" }; // get original url before chrome extension `tab suspender`
    var subtitle : String { return "\(self.url)" };
    var variables : [String : Any] { return ["tabIndex":self.tabIndex, "windowIndex":self.windowIndex, "bundleId":self.bundleId, "tabId":self.id] };
    var icon: [String : Any] { if let iconPath = self.iconPath { return ["path": iconPath ] } else { return ["path": self.fullPath, "type": "fileicon"] }  };
    var type: String? { return "file:skipcheck" };
    var text: [String : Any]? { return ["copy": self.url] };
    var quicklookurl: String? { return self.url };
}
