import XCTest
@testable import FamilyControlsKit
import SharedModels

final class SimpleFamilyControlsKitTests: XCTestCase {
    
    func testAppDiscoveryServiceCreation() {
        let service = AppDiscoveryService()
        XCTAssertNotNil(service)
    }
    
    func testFetchInstalledApps() async throws {
        let service = AppDiscoveryService()
        let apps = try await service.fetchInstalledApps()
        
        XCTAssertFalse(apps.isEmpty)
        XCTAssertTrue(apps.allSatisfy { !$0.displayName.isEmpty })
        XCTAssertTrue(apps.allSatisfy { !$0.bundleID.isEmpty })
    }
}