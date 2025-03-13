import AppKit

class RunningApp: Searchable {
  init(_ app: NSRunningApplication) {
    name = app.localizedName ?? ""
    bundleId = app.bundleIdentifier ?? ""
    fullPath = app.bundleURL?.path ?? ""
  }

  var name: String
  var bundleId: String
  var fullPath: String
  var searchStrings: [String] {
    let fileName = URL(fileURLWithPath: fullPath).deletingPathExtension().lastPathComponent
    return [name, fileName, name.pinyin()]
  }
}

enum RunningApps {
  static var all: [RunningApp] {
    return NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
      .map { RunningApp($0) }
  }
}

