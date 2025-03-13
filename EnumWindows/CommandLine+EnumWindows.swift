import Foundation

protocol CommmandLineCommand {
  static func fromArgv(argv: String) -> CommmandLineCommand?
  static var name: String { get }
  init(value: String)
}

extension CommmandLineCommand {
  static func fromArgv(argv: String) -> CommmandLineCommand? {
    let prefix = "\(name)="
    guard argv.hasPrefix(prefix) else {
      return nil
    }
    let query = argv
      .replacingOccurrences(of: prefix, with: "")
      .replacingOccurrences(of: "\"", with: "")

    return self.init(value: query)
  }
}

struct TabsCommand: CommmandLineCommand {
  static var name: String { return "--tab" }

  let query: String

  init(value: String) {
    query = value
  }
}

struct WindowsCommand: CommmandLineCommand {
  static var name: String { return "--win" }

  let query: String

  init(value: String) {
    query = value
  }
}

struct AppsCommand: CommmandLineCommand {
  static var name: String { return "--app" }

  let query: String

  init(value: String) {
    query = value
  }
}

extension CommandLine {
  static func commands() -> [CommmandLineCommand] {
    var result: [CommmandLineCommand?] = []
    for arg in arguments {
      result.append(AppsCommand.fromArgv(argv: arg))
      result.append(WindowsCommand.fromArgv(argv: arg))
      result.append(TabsCommand.fromArgv(argv: arg))
    }
    return result.flatMap { (command: CommmandLineCommand?) -> [CommmandLineCommand] in
      guard let c = command else { return [] }
      return [c]
    }
  }
}
