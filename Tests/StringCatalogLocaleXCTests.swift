import XCTest

final class StringCatalogLocaleXCTests: XCTestCase {
    private var projectRootURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private let expectedLocales: Set<String> = [
        "en", "zh-Hans", "zh-Hant", "ja", "ko", "de", "fr",
        "es", "pt-BR", "it", "nl", "vi", "th", "id"
    ]

    func testLocalizableCatalogCoversFourteenLocales() throws {
        let catalog = try loadCatalog("Resources/Localizable.xcstrings")
        XCTAssertEqual(catalog["sourceLanguage"] as? String, "en")

        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        let browse = try XCTUnwrap(strings["Browse Icons..."] as? [String: Any])
        let locales = Set((browse["localizations"] as? [String: Any] ?? [:]).keys)
        XCTAssertEqual(locales, expectedLocales)
    }

    func testBrandNameIsNotTranslated() throws {
        let localizable = try loadCatalog("Resources/Localizable.xcstrings")
        let infoPlist = try loadCatalog("Resources/InfoPlist.xcstrings")

        let localizableBrand = try XCTUnwrap(
            (localizable["strings"] as? [String: Any])?["HaoBar"] as? [String: Any]
        )
        XCTAssertEqual(localizableBrand["shouldTranslate"] as? Bool, false)

        let displayName = try XCTUnwrap(
            (infoPlist["strings"] as? [String: Any])?["CFBundleDisplayName"] as? [String: Any]
        )
        XCTAssertEqual(displayName["shouldTranslate"] as? Bool, false)
        let en = ((displayName["localizations"] as? [String: Any])?["en"] as? [String: Any])
        let unit = en?["stringUnit"] as? [String: Any]
        XCTAssertEqual(unit?["value"] as? String, "HaoBar")
    }

    private func loadCatalog(_ relativePath: String) throws -> [String: Any] {
        let url = projectRootURL.appendingPathComponent(relativePath)
        let data = try Data(contentsOf: url)
        let object = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(object as? [String: Any])
    }
}
