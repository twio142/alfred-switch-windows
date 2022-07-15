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
    let processName : String
    let bundleId : String
    
    init(raw: AnyObject, index: Int?, windowTitle: String, processName: String, bundleId: String) {
        tabRaw = raw
        self.index = index
        self.windowTitle = windowTitle
        self.processName = processName
        self.bundleId = bundleId
    }
    
    var rawItem: AnyObject {
        return self.tabRaw
    }
        
    var url : String {
        return performSelectorByName(name: "URL", defaultValue: "")
    }

    var title : String {
        /* Safari uses 'name' as the tab title, while most of the browsers have 'title' there */
        if self.rawItem.responds(to: Selector("name")) {
            return performSelectorByName(name: "name", defaultValue: "")
        }
        return performSelectorByName(name: "title", defaultValue: "")
    }

    var tabId : Int {
        guard let id = performSelectorByName(name: "id", defaultValue: -1) else {
            return -1
        }
        return id
    }

    var tabIndex : Int {
        guard let i = index else {
            return 0
        }
        return i
    }
    
    var searchStrings : [String] {
        return ["Browser", self.url, self.title, self.processName]
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
        guard self.rawItem.responds(to: Selector("currentSession")),
            let session: AnyObject = performSelectorByName(name: "currentSession", defaultValue: nil),
            session.responds(to: Selector("name"))
        else {
            return self.windowTitle
        }

        let selectorResult = session.perform(Selector("name"))
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
    
    let processName : String
    let bundleId : String
    
    init(raw: AnyObject, processName: String, bundleId: String) {
        windowRaw = raw
        self.processName = processName
        self.bundleId = bundleId
    }
    
    var rawItem: AnyObject {
        return self.windowRaw
    }
    
    var tabs : [BrowserTab] {
        let result = performSelectorByName(name: "tabs", defaultValue: [AnyObject]())
        
        return result.enumerated().map { (index, element) in
            if processName == "iTerm" {
                return iTermTab(raw: element, index: index + 1, windowTitle: self.title, processName: self.processName, bundleId: self.bundleId)
            }
            return BrowserTab(raw: element, index: index + 1, windowTitle: self.title, processName: self.processName, bundleId: self.bundleId)
        }
    }

    var title : String {
        /* Safari uses 'name' as the tab title, while most of the browsers have 'title' there */
        if self.rawItem.responds(to: Selector("name")) {
            return performSelectorByName(name: "name", defaultValue: "")
        }
        return performSelectorByName(name: "title", defaultValue: "")
    }
}

class BrowserApplication : BrowserEntity {
    private let app : SBApplication
    private let processName : String
    private let bundleId : String
    
    static func connect(processName: String) -> BrowserApplication? {

        let runningBrowsers = NSWorkspace.shared.runningApplications.filter { $0.localizedName == processName }

        guard runningBrowsers.count > 0 else {
            return nil
        }

        guard let bundleId = runningBrowsers[0].bundleIdentifier else {
            return nil
        }

        guard let app = SBApplication(bundleIdentifier: bundleId) else {
            return nil
        }

        return BrowserApplication(app: app, processName: processName, bundleId: bundleId)
    }
    
    init(app: SBApplication, processName: String, bundleId: String) {
        self.app = app
        self.processName = processName
        self.bundleId = bundleId
    }
    
    var rawItem: AnyObject {
        return app
    }
    
    var windows : [BrowserWindow] {
        let result = performSelectorByName(name: "windows", defaultValue: [AnyObject]())
        return result.map {
            return BrowserWindow(raw: $0, processName: self.processName, bundleId: self.bundleId)
        }
    }
}
