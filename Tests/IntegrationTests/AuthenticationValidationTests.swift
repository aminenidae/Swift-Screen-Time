import XCTest
@testable import CloudKitService
@testable import SharedModels

/// Integration tests for the authentication flow
final class AuthenticationValidationTests: XCTestCase {
    var authService: CloudKitAuthService!
    var familyService: FamilyAccountService!
    var parentAuthService: ParentAuthorizationService!
    var errorService: AuthErrorService!
    
    override func setUp() {
        super.setUp()
        authService = CloudKitAuthService()
        familyService = FamilyAccountService()
        parentAuthService = ParentAuthorizationService()
        errorService = AuthErrorService()
    }
    
    override func tearDown() {
        authService = nil
        familyService = nil
        parentAuthService = nil
        errorService = nil
        super.tearDown()
    }
    
    func testAuthenticationServicesInitialization() {
        XCTAssertNotNil(authService)
        XCTAssertNotNil(familyService)
        XCTAssertNotNil(parentAuthService)
        XCTAssertNotNil(errorService)
    }
    
    func testFamilyCreationFlow() async throws {
        let ownerID = "testOwner123"
        let family = try await familyService.createFamily(name: "Test Family", ownerUserID: ownerID)
        
        XCTAssertEqual(family.name, "Test Family")
        XCTAssertEqual(family.ownerUserID, ownerID)
        XCTAssertTrue(family.sharedWithUserIDs.isEmpty)
        XCTAssertTrue(family.childProfileIDs.isEmpty)
    }
    
    func testFamilyUserManagement() {
        let ownerID = "owner123"
        var family = Family(name: "Test Family", ownerUserID: ownerID)
        
        let userID = "user456"
        familyService.addUserToFamily(&family, userID: userID)
        XCTAssertTrue(family.sharedWithUserIDs.contains(userID))
        
        familyService.removeUserFromFamily(&family, userID: userID)
        XCTAssertFalse(family.sharedWithUserIDs.contains(userID))
    }
    
    func testFamilyChildManagement() {
        let ownerID = "owner123"
        var family = Family(name: "Test Family", ownerUserID: ownerID)
        
        let childID = "child789"
        familyService.addChildToFamily(&family, childProfileID: childID)
        XCTAssertTrue(family.childProfileIDs.contains(childID))
        
        familyService.removeChildFromFamily(&family, childProfileID: childID)
        XCTAssertFalse(family.childProfileIDs.contains(childID))
    }
    
    func testAuthErrorHandling() {
        let notAuthenticatedError = CKError(.notAuthenticated)
        let message = errorService.handleAuthError(notAuthenticatedError)
        XCTAssertTrue(message.contains("iCloud account not available"))
        
        let permissionError = CKError(.permissionFailure)
        let permissionMessage = errorService.handleAuthError(permissionError)
        XCTAssertTrue(permissionMessage.contains("Permission denied"))
    }
    
    func testAccountRecoveryGuidance() {
        let guidance = errorService.getAccountRecoveryGuidance()
        XCTAssertFalse(guidance.isEmpty)
        XCTAssertTrue(guidance.contains("iCloud account"))
    }
    
    func testRestrictedAccountHandling() {
        let message = errorService.handleRestrictedAccount()
        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(message.contains("restricted"))
    }
    
    func testParentAuthorizationService() {
        XCTAssertFalse(parentAuthService.isAuthorizationValid())
        parentAuthService.clearAuthorization()
    }
    
    func testBiometricTypeDetection() {
        let biometricType = parentAuthService.getBiometricType()
        XCTAssertNotNil(biometricType)
    }
}