import Foundation

protocol AlfredItem {
    var arg : String { get };
    var title : String { get };
    var subtitle : String { get };
    var variables : [String : Any] { get };
    var fullPath : String { get };
    var searchStrings : [String] { get };
    var icon: [String : Any] { get };
    var type: String? { get };
    var text: [String : Any]? { get };
    var quicklookurl: String? { get };
}

extension AlfredItem {

    var jsonItem : [String : Any] {
        var item = [
            "title": self.title,
            "subtitle": self.subtitle,
            "arg": self.arg,
            "icon": self.icon,
            "match": self.searchStrings.joined(separator: " "),
            "variables": self.variables
        ] as [String : Any]
        if let type = self.type {
            item["type"] = type
        }
        if let text = self.text {
            item["text"] = text
        }
        if let quicklookurl = self.quicklookurl {
            item["quicklookurl"] = quicklookurl
        }
        return item
    }
}

struct AlfredDocument {
    let items : [AlfredItem]

    init(withItems: [AlfredItem]) {
        self.items = withItems;
    }

    var jsonString : String {
        func json(from object:Any) -> String? {
            guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]) else {
                return nil
            }
            return String(data: data, encoding: String.Encoding.utf8)
        }

        guard !self.items.isEmpty else {
            return "{\"items\": [{\"title\": \"No Results\", \"valid\": false}]}"
        }
        return json(from: ["items": self.items.map { return $0.jsonItem }]) ?? ""
    }
}
