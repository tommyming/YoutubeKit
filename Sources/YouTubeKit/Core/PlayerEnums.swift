import Foundation

/// Represents the state of the YouTube player.
/// Mapped to YouTube's IFrame API states.
public enum PlayerState: Int, CaseIterable, Sendable {
    case unstarted = -1
    case ended = 0
    case playing = 1
    case paused = 2
    case buffering = 3
    case cued = 5
}

/// Represents errors that can occur within the YouTube player.
public enum PlayerError: Error, Sendable {
    case domainRestricted
    case videoNotFound
    case html5Error
    case invalidVideoId
    case unknown(Int?)
}

/// Represents a validated YouTube video identifier.
public struct VideoId: Sendable {
    /// The validated video ID string
    public let value: String

    /// Creates a VideoId from a string, validating and sanitizing it.
    /// - Parameter videoId: The raw video ID string to validate
    /// - Returns: A valid VideoId, or nil if invalid
    public init?(_ videoId: String) {
        guard !videoId.isEmpty else {
            return nil
        }

        // Sanitize: Remove any characters that could cause issues
        let sanitized = videoId.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .alphanumerics.inverted)
            .joined()

        // Validate: Check if it's a valid YouTube video ID format
        // YouTube video IDs are typically 11 characters (can vary)
        // Valid characters: letters, numbers, hyphens, underscores
        let isValidFormat = sanitized.count >= 10 && sanitized.count <= 15 && !sanitized.isEmpty

        guard isValidFormat else {
            return nil
        }

        self.value = sanitized
    }

    /// Validates and sanitizes a video ID string.
    /// - Parameter videoId: The raw video ID string
    /// - Returns: A validated and sanitized VideoId
    /// - Throws: PlayerError if the video ID is invalid
    public static func validateAndSanitize(_ videoId: String) throws -> VideoId {
        guard !videoId.isEmpty else {
            throw PlayerError.unknown(nil)  // Empty video ID
        }

        // Sanitize: Remove any characters that could cause issues
        let sanitized = videoId.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .alphanumerics.inverted)
            .joined()

        // Validate: Check if it's a valid YouTube video ID format
        let isValidFormat = sanitized.count >= 10 && sanitized.count <= 15 && !sanitized.isEmpty

        guard isValidFormat else {
            throw PlayerError.videoNotFound  // Invalid format
        }

        return VideoId(sanitized)
    }
}
