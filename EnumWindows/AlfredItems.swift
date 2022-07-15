import Foundation

extension WindowInfoDict : AlfredItem {
    var title : String { return self.name };
    var subtitle : String { return self.processName };
    var arg: String { return "" };
    var variables : [String : Any] { return ["bundleId":self.bundleId] };
}

extension BrowserTab : AlfredItem {
    var arg: String { return "" };
    var subtitle : String { return "\(self.url)" };
    var variables : [String : Any] { return ["tabIndex":self.tabIndex, "windowTitle":self.windowTitle, "bundleId":self.bundleId] };
}
