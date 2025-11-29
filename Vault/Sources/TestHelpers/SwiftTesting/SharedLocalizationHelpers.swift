import Foundation
import Testing

/// Creates an assertion using Swift Testing that localizations exist for all bundles.
public func expectLocalizedKeyAndValuesExist(
    in presentationBundle: Bundle,
    _ table: String,
    sourceLocation: SourceLocation = #_sourceLocation,
) {
    guard Test.current != nil else { fatalError("This must be running within a test!") }
    let localizationBundles = allLocalizationBundles(in: presentationBundle, sourceLocation: sourceLocation)
    let localizedStringKeys = allLocalizedStringKeys(
        in: localizationBundles,
        table: table,
        sourceLocation: sourceLocation,
    )

    for (bundle, localization) in localizationBundles {
        for key in localizedStringKeys {
            let localizedString = bundle.localizedString(forKey: key, value: nil, table: table)

            let language = Locale.current.localizedString(forLanguageCode: localization) ?? ""
            if localizedString == key {
                Issue.record(
                    "Missing \(language) (\(localization)) localized string for key: '\(key)' in table: '\(table)'",
                    sourceLocation: sourceLocation,
                )
            } else if localizedString.isEmpty {
                Issue.record(
                    "Empty string for '\(key)' in table: '\(table)' for \(language) (\(localization))",
                    sourceLocation: sourceLocation,
                )
            }
        }
    }
}

private typealias LocalizedBundle = (bundle: Bundle, localization: String)

private func allLocalizationBundles(
    in bundle: Bundle,
    sourceLocation: SourceLocation,
) -> [LocalizedBundle] {
    bundle.localizations.compactMap { localization in
        guard
            let path = bundle.path(forResource: localization, ofType: "lproj"),
            let localizedBundle = Bundle(path: path)
        else {
            Issue.record("Couldn't find bundle for localization: \(localization)", sourceLocation: sourceLocation)
            return nil
        }

        return (localizedBundle, localization)
    }
}

private func allLocalizedStringKeys(
    in bundles: [LocalizedBundle],
    table: String,
    sourceLocation: SourceLocation,
) -> Set<String> {
    bundles.reduce([]) { acc, current in
        guard
            let path = current.bundle.path(forResource: table, ofType: "strings"),
            let strings = NSDictionary(contentsOfFile: path),
            let keys = strings.allKeys as? [String]
        else {
            Issue.record(
                "Couldn't load localized strings for localization: \(current.localization)",
                sourceLocation: sourceLocation,
            )
            return acc
        }

        return acc.union(Set(keys))
    }
}
