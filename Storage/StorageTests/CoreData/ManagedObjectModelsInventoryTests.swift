
import Foundation
import XCTest

@testable import Storage

private typealias ModelVersion = ManagedObjectModelsInventory.ModelVersion
private typealias IntrospectionError = ManagedObjectModelsInventory.IntrospectionError

/// Test cases for `ManagedObjectModelsInventory`.
///
final class ManagedObjectModelsInventoryTests: XCTestCase {

    private let bundle = Bundle(for: CoreDataManager.self)
    private let packageName = "WooCommerce"

    func testItCanLoadTheExpectedModelVersions() throws {
        // Given
        let expectedVersionNames = [
            "Model",
            "Model 2",
            "Model 3",
            "Model 4",
            "Model 5",
            "Model 6",
            "Model 7",
            "Model 8",
            "Model 9",
            "Model 10",
            "Model 11",
            "Model 12",
            "Model 13",
            "Model 14",
            "Model 15",
            "Model 16",
            "Model 17",
            "Model 18",
            "Model 19",
            "Model 20",
            "Model 21",
            "Model 22",
            "Model 23",
            "Model 24",
            "Model 25",
            "Model 26",
            "Model 27",
            "Model 28",
        ]

        // When
        let inventory = try ManagedObjectModelsInventory.from(packageName: packageName, bundle: bundle)

        let modelVersionNames = inventory.modelVersions.map { $0.name }

        // Then
        // We'll cut the version names up to the length of `expectedVersionNames` so that this
        // test will still pass even if new model versions are added. This is just for
        // maintainability.
        let truncatedModelVersionNames = Array(modelVersionNames[..<expectedVersionNames.count])

        XCTAssertEqual(truncatedModelVersionNames, expectedVersionNames)
    }

    /// Tests that the model versions are sorted according to our convention of incrementing
    /// the number names.
    func testItSortsTheModelsUsingTheConvention() throws {
        // Given
        let modelVersions = [
            ModelVersion(name: "Model 301"),
            ModelVersion(name: "Model 311"),
            ModelVersion(name: "Model 3"),
            ModelVersion(name: "Model 1"),
            ModelVersion(name: "Model"),
            ModelVersion(name: "Model 4"),
            ModelVersion(name: "Model 5"),
            ModelVersion(name: "Model 7"),
            ModelVersion(name: "Model 65"),
            ModelVersion(name: "Model 13"),
            ModelVersion(name: "Model 130"),
            ModelVersion(name: "Model 10"),
        ]

        // When
        let dummyURL = try XCTUnwrap(URL(string: "https://example.com"))
        let sortedModelVersions = ManagedObjectModelsInventory(packageURL: dummyURL, modelVersions: modelVersions).modelVersions

        // Then
        let expectedSortedNames = [
            "Model",
            "Model 1",
            "Model 3",
            "Model 4",
            "Model 5",
            "Model 7",
            "Model 10",
            "Model 13",
            "Model 65",
            "Model 130",
            "Model 301",
            "Model 311",
        ]
        XCTAssertEqual(sortedModelVersions.map { $0.name }, expectedSortedNames)
    }

    func testItThrowsAnErrorIfThePackageNameDoesNotPointToAnMomdDirectory() {
        // Given
        let packageName = "InvalidPackageName"

        // When-Then
        XCTAssertThrowsError(try ManagedObjectModelsInventory.from(packageName: packageName, bundle: bundle)) { error in
            XCTAssertEqual(error as? IntrospectionError, IntrospectionError.cannotFindMomd)
        }
    }
}
