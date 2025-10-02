import Foundation
import SharedModels

// MARK: - Validation Models

public struct ValidationDetails: Codable {
    public let validationScore: Double        // 0.0 (suspicious) to 1.0 (genuine)
    public let confidenceLevel: Double        // Algorithm confidence in assessment
    public let detectedPatterns: [GamingPattern]
    public let engagementIndicators: EngagementMetrics
    public let validatedAt: Date
    public let validationAlgorithmVersion: String
    
    public init(
        validationScore: Double,
        confidenceLevel: Double,
        detectedPatterns: [GamingPattern],
        engagementIndicators: EngagementMetrics,
        validatedAt: Date,
        validationAlgorithmVersion: String
    ) {
        self.validationScore = validationScore
        self.confidenceLevel = confidenceLevel
        self.detectedPatterns = detectedPatterns
        self.engagementIndicators = engagementIndicators
        self.validatedAt = validatedAt
        self.validationAlgorithmVersion = validationAlgorithmVersion
    }
}

public enum GamingPattern: Codable, Equatable {
    case rapidAppSwitching(frequency: Double)
    case suspiciouslyLongSession(duration: TimeInterval)
    case exactHourBoundaries
    case deviceLockDuringSession
    case backgroundUsage
    
    enum CodingKeys: CodingKey {
        case rapidAppSwitching
        case suspiciouslyLongSession
        case exactHourBoundaries
        case deviceLockDuringSession
        case backgroundUsage
        case frequency
        case duration
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let _ = try? container.decodeNil(forKey: .exactHourBoundaries) {
            self = .exactHourBoundaries
        } else if let _ = try? container.decodeNil(forKey: .deviceLockDuringSession) {
            self = .deviceLockDuringSession
        } else if let _ = try? container.decodeNil(forKey: .backgroundUsage) {
            self = .backgroundUsage
        } else if let frequency = try? container.decode(Double.self, forKey: .frequency) {
            self = .rapidAppSwitching(frequency: frequency)
        } else if let duration = try? container.decode(TimeInterval.self, forKey: .duration) {
            self = .suspiciouslyLongSession(duration: duration)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid GamingPattern value"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .rapidAppSwitching(let frequency):
            try container.encode(frequency, forKey: .frequency)
        case .suspiciouslyLongSession(let duration):
            try container.encode(duration, forKey: .duration)
        case .exactHourBoundaries:
            try container.encodeNil(forKey: .exactHourBoundaries)
        case .deviceLockDuringSession:
            try container.encodeNil(forKey: .deviceLockDuringSession)
        case .backgroundUsage:
            try container.encodeNil(forKey: .backgroundUsage)
        }
    }
}

public struct EngagementMetrics: Codable {
    public let appStateChanges: Int
    public let averageSessionLength: TimeInterval
    public let interactionDensity: Double
    public let deviceMotionCorrelation: Double?
    
    public init(
        appStateChanges: Int,
        averageSessionLength: TimeInterval,
        interactionDensity: Double,
        deviceMotionCorrelation: Double?
    ) {
        self.appStateChanges = appStateChanges
        self.averageSessionLength = averageSessionLength
        self.interactionDensity = interactionDensity
        self.deviceMotionCorrelation = deviceMotionCorrelation
    }
}

public enum ValidationLevel: String, Codable, CaseIterable {
    case lenient = "lenient"
    case moderate = "moderate"
    case strict = "strict"
    
    public var confidenceThreshold: Double {
        switch self {
        case .lenient:
            return 0.90
        case .moderate:
            return 0.75
        case .strict:
            return 0.60
        }
    }
}

public struct ValidationResult: Codable {
    public let isValid: Bool
    public let validationScore: Double
    public let confidenceLevel: Double
    public let detectedPatterns: [GamingPattern]
    public let engagementMetrics: EngagementMetrics
    public let validationLevel: ValidationLevel
    public let adjustmentFactor: Double  // 0.0 to 1.0 multiplier for points
    
    public init(
        isValid: Bool,
        validationScore: Double,
        confidenceLevel: Double,
        detectedPatterns: [GamingPattern],
        engagementMetrics: EngagementMetrics,
        validationLevel: ValidationLevel,
        adjustmentFactor: Double
    ) {
        self.isValid = isValid
        self.validationScore = validationScore
        self.confidenceLevel = confidenceLevel
        self.detectedPatterns = detectedPatterns
        self.engagementMetrics = engagementMetrics
        self.validationLevel = validationLevel
        self.adjustmentFactor = adjustmentFactor
    }
}