import Foundation
import AppKit

/// Removes browser window from the list of windows and adds tabs to the results array
func searchBrowserTabsIfNeeded(bundleId: String,
                               query: String,
                               results: inout [[AlfredItem]]) {

    let browserTabs =
        BrowserApplication.connect(bundleId: bundleId)?.windows
            .filter { !$0.title.isEmpty } // filter out Chrome PWAs
            .flatMap { return $0.tabs }
            .search(query)

    if let browserTabs = browserTabs {
        browserTabs.getIcons()
        results.append(browserTabs)
    }
}

func search(query: String, tabMode: Bool) {
    var results : [[AlfredItem]] = []

    if tabMode {
        for browserId in ["com.apple.Safari",
                                  "com.google.Chrome",
                                  "company.thebrowser.Browser"] {
            searchBrowserTabsIfNeeded(bundleId: browserId,
                                      query: query,
                                      results: &results) // inout!
        }
    } else {
        results.append(Windows.all.search(query))
    }

    let alfredItems : [AlfredItem] = results.flatMap { $0 }

    print(AlfredDocument(withItems: alfredItems).jsonString)
}

func handleCatalinaScreenRecordingPermission() {
    guard let firstWindow = Windows.any else {
        return
    }

    guard !firstWindow.hasName else {
        return
    }

    let windowImage = CGWindowListCreateImage(.null, .optionIncludingWindow,
                                              firstWindow.number,
                                              [.boundsIgnoreFraming, .bestResolution])
    if windowImage == nil {
        debugPrint("This workflow requires permission for screen recording. Go to System Preferences > Security & Privacy > Privacy > Screen Recording, authorize Alfred and re-launch.")
        exit(1)
    }
}

handleCatalinaScreenRecordingPermission()

/*
 a naive perf test, decided to keep it here for convenience

let start = DispatchTime.now() // <<<<<<<<<< Start time

for _ in 0...100 {
    search(query: "pull", tabMode: false)
}
let end = DispatchTime.now()   // <<<<<<<<<<   end time
let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests

print("TIME SPENT: \(timeInterval)")
*/

for command in CommandLine.commands() {
    switch command {
    case let searchCommand as WindowsCommand:
        search(query: searchCommand.query, tabMode: false)
        exit(0)
    case let searchCommand as TabsCommand:
        search(query: searchCommand.query, tabMode: true)
        exit(0)
    default:
        print("Usage:")
        print("[--win=<query>] | [--tab=<query>]")
        exit(1)
    }
}
