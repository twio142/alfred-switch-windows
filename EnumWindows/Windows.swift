import Foundation
import AppKit

class WindowInfoDict : Searchable, ProcessNameProtocol {
    private let windowInfoDict : Dictionary<NSObject, AnyObject>;

    init(rawDict : UnsafeRawPointer) {
        windowInfoDict = unsafeBitCast(rawDict, to: CFDictionary.self) as Dictionary
    }

    var name : String {
        return self.dictItem(key: "kCGWindowName", defaultValue: "")
    }

    var hasName : Bool {
        return self.windowInfoDict["kCGWindowName" as NSObject] != nil
    }

    var number: UInt32 {
        return self.dictItem(key: "kCGWindowNumber", defaultValue: 0)
    }

    var processName : String {
        return self.dictItem(key: "kCGWindowOwnerName", defaultValue: "")
    }

    var appName : String {
        return self.dictItem(key: "kCGWindowOwnerName", defaultValue: "")
    }

    var pid : Int {
        return self.dictItem(key: "kCGWindowOwnerPID", defaultValue: -1)
    }

    var bundleId : String {
        let app = NSWorkspace.shared.runningApplications.filter { $0.processIdentifier == self.pid }
        guard !app.isEmpty else {
            return ""
        }
        return app[0].bundleIdentifier ?? ""
}

    var bounds : CGRect {
        let dict = self.dictItem(key: "kCGWindowBounds", defaultValue: NSDictionary())
        guard let bounds = CGRect.init(dictionaryRepresentation: dict) else {
            return CGRect.zero
        }
        return bounds
    }

    var alpha : Float {
        return self.dictItem(key: "kCGWindowAlpha", defaultValue: 0.0)
    }

    var layer : Int {
        return self.dictItem(key: "kCGWindowLayer", defaultValue: -1)
    }

    func dictItem<T>(key : String, defaultValue : T) -> T {
        guard let value = windowInfoDict[key as NSObject] as? T else {
            return defaultValue
        }
        return value
    }

    static func == (lhs: WindowInfoDict, rhs: WindowInfoDict) -> Bool {
        return lhs.processName == rhs.processName && lhs.name == rhs.name
    }

    var hashValue: Int {
        return "\(self.processName)-\(self.name)".hashValue
    }

    var fullPath : String {
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: self.bundleId)?.path ?? ""
    }

    var searchStrings: [String] {
        let fileName = URL(fileURLWithPath: self.fullPath).deletingPathExtension().lastPathComponent
        let nameMatch = self.name.pinyin().replacingOccurrences(of: "[^a-zA-Z0-9]", with: " ", options: [.regularExpression]).trimmingCharacters(in: .whitespacesAndNewlines)
        return [self.processName, self.processName.pinyin(), fileName, self.name, nameMatch]
    }

    var isVisible : Bool {
        return self.alpha > 0 && self.layer == 0
    }
}

struct Windows {
    static var filterList : [String] = ["", "com.apple.dock", "com.apple.WindowManager"]

    static var any : WindowInfoDict? {
        get {
            guard let wl = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) else {
                return nil
            }

            return (0..<CFArrayGetCount(wl)).flatMap { (i : Int) -> [WindowInfoDict] in
                guard let windowInfoRef = CFArrayGetValueAtIndex(wl, i) else {
                    return []
                }

                let wi = WindowInfoDict(rawDict: windowInfoRef)
                return [wi]
            }.first
        }
    }

    static var all : [WindowInfoDict] {
        get {
            guard let wl = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) else {
                return []
            }

            return (0..<CFArrayGetCount(wl)).flatMap { (i : Int) -> [WindowInfoDict] in
                guard let windowInfoRef = CFArrayGetValueAtIndex(wl, i) else {
                    return []
                }

                let wi = WindowInfoDict(rawDict: windowInfoRef)

                guard wi.isVisible && !wi.name.isEmpty && !filterList.contains(wi.bundleId) else {
                    return []
                }

                return [wi]
            }
        }
    }
}
