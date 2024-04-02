import Foundation
import AppKit
import ScriptingBridge

protocol BrowserEntity {
    var rawItem : AnyObject { get }
}

protocol BrowserNamedEntity : BrowserEntity {
    var title : String { get }
}

extension BrowserEntity {
    func performSelectorByName<T>(name : String, defaultValue : T) -> T {
        let sel = Selector(name)
        guard self.rawItem.responds(to: sel) else {
            return defaultValue
        }

        let selectorResult = self.rawItem.perform(sel)

        guard let retainedValue = selectorResult?.takeRetainedValue() else {
            return defaultValue
        }

        guard let result = retainedValue as? T else {
            return defaultValue
        }

        return result
    }
}

class BrowserTab : BrowserNamedEntity, Searchable, ProcessNameProtocol {
    private let tabRaw : AnyObject
    private let index : Int?

    let windowTitle : String
    let windowIndex : Int
    let processName : String
    let bundleId : String
    let fullPath : String

    init(raw: AnyObject, index: Int?, windowTitle: String, windowIndex: Int, processName: String, bundleId: String, fullPath: String) {
        tabRaw = raw
        self.index = index
        self.windowTitle = windowTitle
        self.windowIndex = windowIndex
        self.processName = processName
        self.bundleId = bundleId
        self.fullPath = fullPath
    }

    var rawItem: AnyObject {
        return self.tabRaw
    }

    var url : String {
        return performSelectorByName(name: "URL", defaultValue: "")
    }

    var title : String {
        /* Safari uses 'name' as the tab title, while most of the browsers have 'title' there */
        if self.rawItem.responds(to: #selector(NSImage.name)) {
            return performSelectorByName(name: "name", defaultValue: "")
        }
        return performSelectorByName(name: "title", defaultValue: "")
    }

    var tabIndex : Int {
        guard let i = index else {
            return 0
        }
        return i
    }

    var searchStrings : [String] {
        /* Use also the app's file name in search string */
        let fileName = Bundle(path: self.fullPath)?.infoDictionary?["CFBundleName"] as? String ?? ""
        /* Match url only by the core part of its domain */
        let urlMatch = self.url.replacingOccurrences(of: "chrome-extension://[a-z]+/suspended.html#.+?&uri=", with: "", options: [.regularExpression]).replacingOccurrences(of: "^https?://(www\\d?\\.|m\\.)?([^\\/]+?)\\.(co\\.uk|co\\.jp|[a-z]+)/.+", with: "$2", options: [.regularExpression]).replacingOccurrences(of: "[^A-Za-z0-9]", with: " ", options: [.regularExpression])
        return [urlMatch, self.title, self.processName, fileName]
    }

    /*
     (lldb) po raw.perform("URL").takeRetainedValue()
     https://encrypted.google.com/search?hl=en&q=objc%20mac%20list%20Browser%20tabs#hl=en&q=swift+call+metho+by+name


     (lldb) po raw.perform("name").takeRetainedValue()
     scriptingbridge Browsertab - Google Search
 */
}

class iTermTab : BrowserTab {
    override var title : String {
        guard self.rawItem.responds(to: Selector(("currentSession"))),
            let session: AnyObject = performSelectorByName(name: "currentSession", defaultValue: nil),
            session.responds(to: #selector(NSImage.name))
        else {
            return self.windowTitle
        }

        let selectorResult = session.perform(#selector(NSImage.name))
        guard let retainedValue = selectorResult?.takeRetainedValue(),
            let tabName = retainedValue as? String
        else {
            return self.windowTitle
        }
        return tabName
    }
}

class BrowserWindow : BrowserNamedEntity {
    private let windowRaw : AnyObject
    private let index : Int?

    let processName : String
    let bundleId : String
    let fullPath : String

    init(raw: AnyObject, index: Int?, processName: String, bundleId: String, fullPath: String) {
        windowRaw = raw
        self.index = index
        self.processName = processName
        self.bundleId = bundleId
        self.fullPath = fullPath
    }

    var rawItem: AnyObject {
        return self.windowRaw
    }

    var tabs : [BrowserTab] {
        let result = performSelectorByName(name: "tabs", defaultValue: [AnyObject]())

        return result.enumerated().map { (index, element) in
            if processName == "iTerm" {
                return iTermTab(raw: element, index: index, windowTitle: self.title, windowIndex: self.windowIndex, processName: self.processName, bundleId: self.bundleId, fullPath: self.fullPath)
            }
            return BrowserTab(raw: element, index: index, windowTitle: self.title, windowIndex: self.windowIndex, processName: self.processName, bundleId: self.bundleId, fullPath: self.fullPath)
        }
    }

    var title : String {
        /* Safari uses 'name' as the tab title, while most of the browsers have 'title' there */
        if self.rawItem.responds(to: #selector(NSImage.name)) {
            return performSelectorByName(name: "name", defaultValue: "")
        }
        return performSelectorByName(name: "title", defaultValue: "")
    }

    var windowIndex : Int {
        guard let i = index else {
            return 0
        }
        return i
    }
}

class BrowserApplication : BrowserEntity {
    private let app : SBApplication
    private let processName : String
    private let bundleId : String
    private let fullPath : String

    static func connect(bundleId: String) -> BrowserApplication? {

        let runningBrowsers = NSWorkspace.shared.runningApplications.filter { $0.bundleIdentifier == bundleId }

        guard !runningBrowsers.isEmpty else {
            return nil
        }

        guard let fullPath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)?.path else {
            return nil
        }

        guard let app = SBApplication(bundleIdentifier: bundleId) else {
            return nil
        }

        guard let processName = runningBrowsers[0].localizedName else {
            return nil
        }

        return BrowserApplication(app: app, processName: processName, bundleId: bundleId, fullPath: fullPath)
    }

    init(app: SBApplication, processName: String, bundleId: String, fullPath: String) {
        self.app = app
        self.processName = processName
        self.bundleId = bundleId
        self.fullPath = fullPath
    }

    var rawItem: AnyObject {
        return app
    }

    var windows : [BrowserWindow] {
        let result = performSelectorByName(name: "windows", defaultValue: [AnyObject]())
        return result.enumerated().map { (index, element) in
            return BrowserWindow(raw: element, index: index, processName: self.processName, bundleId: self.bundleId, fullPath: self.fullPath)
        }
    }
}
