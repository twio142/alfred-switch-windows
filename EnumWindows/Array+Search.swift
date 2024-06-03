import Foundation
import K3Pinyin

protocol Searchable {
    var searchStrings : [String] { get }
}

extension Array where Element:Searchable {
    func search(_ query: String) -> [Element] {
        guard !query.isEmpty else {
            return self
        }
        let components : ArraySlice<String> =
            ArraySlice(
                query.components(separatedBy:  " ")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        return search(components: components)
    }

    private func search(components: ArraySlice<String>) -> [Element] {
        guard let q = components.first else {
            return self
        }

        let result = self.filter {
            let hits = $0.searchStrings.filter { $0.localizedCaseInsensitiveContains(q) }
            return !hits.isEmpty
        }

        return result.search(components: components.dropFirst(1))
    }
}

extension String {
    func pinyin() -> String {
        let check = NSPredicate(format: "SELF MATCHES %@", ".*\\p{Script=Han}.*")
        return check.evaluate(with: self) ? self.k3.pinyin([.separator(" ")]).folding(options: .diacriticInsensitive, locale: .current) : self
    }
}