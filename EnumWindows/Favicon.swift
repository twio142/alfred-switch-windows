import Foundation
import SQLite

let profilePath = ProcessInfo.processInfo.environment["profile"] ?? ""
let expandedProfilePath = NSString(string: profilePath).expandingTildeInPath
let profile = URL(fileURLWithPath: expandedProfilePath)
let cacheDir = URL(fileURLWithPath: ProcessInfo.processInfo.environment["alfred_workflow_cache"] ?? "")

func copyDb(name: String) -> URL? {
  let cache = cacheDir.appendingPathComponent(name)
  let dbFile = profile.appendingPathComponent(name)

  do {
    let fileManager = FileManager.default
    let cacheAttributes = try FileManager.default.attributesOfItem(atPath: cache.path)
    let cacheModificationDate = cacheAttributes[.modificationDate] as? Date ?? Date()

    if Date().timeIntervalSince(cacheModificationDate) <= 60 {
      return cache
    }
    if fileManager.fileExists(atPath: cache.path) {
      try fileManager.removeItem(at: cache)
    }
    try fileManager.copyItem(at: dbFile, to: cache)
    return cache
  } catch {
    log(String(describing: error))
    return nil
  }
}

func historyDb() -> Connection? {
  guard let history = copyDb(name: "History"),
        let favicons = copyDb(name: "Favicons")
  else {
    return nil
  }

  do {
    let db = try Connection(history.path)
    try db.run("ATTACH DATABASE ? AS favicons", favicons.path)
    return db
  } catch {
    log("Failed to attach favicons database to history database")
    return nil
  }
}

func cacheFavicon(blob: Blob, uid: Int64, lastUpdated: TimeInterval) -> URL? {
  let favDir = cacheDir.appendingPathComponent("Favicons-Cache")
  try? FileManager.default.createDirectory(at: favDir, withIntermediateDirectories: true)

  let favFile = favDir.appendingPathComponent(String(uid))
  if let fileModificationDate = try? FileManager.default.attributesOfItem(atPath: favFile.path)[.modificationDate] as? Date,
     Date().timeIntervalSince(fileModificationDate) <= lastUpdated
  {
    return favFile
  }

  do {
    let imageData = Data(blob.bytes)
    try imageData.write(to: favFile)
    try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: lastUpdated)], ofItemAtPath: favFile.path)
    return favFile
  } catch {
    log("Failed to write favicon to cache")
    return nil
  }
}

extension Array where Element: BrowserTab {
  func getIcons() {
    guard let db = historyDb() else {
      log("Failed to open history database")
      return
    }

    let tabsTable = Table("tabs")
    let url = Expression<String>(value: "url")

    do {
      try db.run(tabsTable.drop(ifExists: true))
      try db.run(tabsTable.create { t in
        t.column(url)
      })

      for tab in self {
        try db.run(tabsTable.insert(url <- tab.url))
      }
    } catch {
      log("Failed to create and populate tabs table")
      log(String(describing: error))
    }

    let CREATE_TEMP_TABLE = """
        CREATE TEMPORARY TABLE IF NOT EXISTS max_width_id AS
        SELECT icon_id, id
        FROM (
            SELECT icon_id, id, ROW_NUMBER() OVER(PARTITION BY icon_id ORDER BY width DESC) as rn
            FROM favicon_bitmaps
        ) tmp
        WHERE rn = 1
    """
    do {
      try db.run(CREATE_TEMP_TABLE)
    } catch {
      log("Failed to create temporary table")
    }

    let FAVICON_SEARCH = """
        SELECT tabs.url, favicon_bitmaps.id AS uid, favicon_bitmaps.image_data, favicon_bitmaps.last_updated / 1000 - \(Date().timeIntervalSince1970)
        FROM tabs
        LEFT OUTER JOIN icon_mapping ON icon_mapping.page_url = tabs.url
        LEFT OUTER JOIN max_width_id ON max_width_id.icon_id = icon_mapping.icon_id
        LEFT OUTER JOIN favicon_bitmaps ON favicon_bitmaps.id = max_width_id.id
        GROUP BY tabs.url
    """
    var icons: [(url: String, uid: Int64, imageData: Blob, lastUpdated: TimeInterval)] = []
    do {
      try db.prepare(FAVICON_SEARCH).forEach { row in
        if let url = row[0] as? String,
           let uid = row[1] as? Int64,
           let imageData = row[2] as? Blob,
           let lastUpdated = row[3] as? TimeInterval
        {
          icons.append((url: url, uid: uid, imageData: imageData, lastUpdated: lastUpdated))
        }
      }
    } catch {
      log("Failed to execute favicon search query")
    }

    for tab in self {
      if let icon = icons.first(where: { $0.url == tab.url }) {
        tab.iconPath = cacheFavicon(blob: icon.imageData, uid: icon.uid, lastUpdated: icon.lastUpdated)?.path
      }
    }
  }
}
