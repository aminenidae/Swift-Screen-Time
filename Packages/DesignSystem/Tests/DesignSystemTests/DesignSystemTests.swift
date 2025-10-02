import XCTest
@testable import DesignSystem

final class DesignSystemTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(DesignSystem().text, "Hello, World!")
    }
    
    func testColorTokens() throws {
        // Test that color tokens are accessible
        let _ = DesignSystemColor.primaryBrand
        let _ = DesignSystemColor.accent
        let _ = DesignSystemColor.success
    }
    
    func testSpacingTokens() throws {
        // Test that spacing tokens are accessible
        let _ = Spacing.xs
        let _ = Spacing.md
        let _ = Spacing.lg
    }
    
    func testButtonStyles() throws {
        // Test that button styles are accessible
        let _ = DSButtonStyle.primary
        let _ = DSButtonStyle.secondary
        let _ = DSButtonStyle.destructive
    }
    
    func testCardStyles() throws {
        // Test that card styles are accessible
        let _ = DSCardStyle.elevated
        let _ = DSCardStyle.filled
    }
    
    func testPointsDisplayStyles() throws {
        // Test that points display styles are accessible
        let _ = DSPointsDisplayStyle.small
        let _ = DSPointsDisplayStyle.medium
        let _ = DSPointsDisplayStyle.large
    }
}