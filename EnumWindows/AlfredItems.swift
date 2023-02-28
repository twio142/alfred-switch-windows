import Foundation

extension WindowInfoDict : AlfredItem {
    var title : String { return self.name };
    var subtitle : String { return self.processName };
    var arg: String { return "" };
    var variables : [String : Any] { return ["bundleId":self.bundleId, "windowTitle":self.windowTitle, "windowId":self.number] };
}

extension BrowserTab : AlfredItem {
    var arg: String { return "\(self.url.replacingOccurrences(of: "chrome-extension://[a-z]+/suspended.html#.+?&uri=", with: "", options: [.regularExpression]))" }; // get original url before chrome extension `tab suspender`
    var subtitle : String { return "\(self.url)" };
    var variables : [String : Any] { return ["tabIndex":self.tabIndex, "windowIndex":self.windowIndex, "bundleId":self.bundleId, "tabTitle":self.title] };
}
