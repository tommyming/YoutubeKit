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
    case unknown(Int?)
}
