import Foundation

protocol AlfredItem {
    var arg : String { get };
    var title : String { get };
    var icon : String { get };
    var subtitle : String { get };
    var processName : String { get };
    var variables : [String : Any] { get };
    var bundleId : String { get };
}


extension AlfredItem {

    var icon : String { return AppIcon(appName: self.bundleId).path };

    var jsonItem : [String : Any] {
        return [
            "title": self.title,
            "subtitle": self.subtitle,
            "arg": self.arg,
            "icon": ["path": self.icon, "type": "fileicon"],
            "variables": self.variables
        ]
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
        
        return json(from: ["items": self.items.map { return $0.jsonItem }]) ?? ""
    }
}
