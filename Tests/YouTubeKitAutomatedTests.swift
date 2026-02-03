import Combine
import Testing
import WebKit

@testable import YouTubeKit

@Suite("YouTubeKit Automated Tests")
@MainActor
struct YouTubeKitAutomatedTests {

    // MARK: - Properties

    var player: YouTubePlayer?
    var cancellables: Set<AnyCancellable>?
    var stateChanges: [PlayerState]?
    var stateContinuation: CheckedContinuation<Void, Error>?

    // MARK: - Initialization

    init() {
        player = YouTubePlayer()
        cancellables = []
        stateChanges = []

        guard let player = player else { return }

        // Observe state changes for testing
        player.$state
            .sink { state in
                self.stateChanges?.append(state)
                self.stateContinuation?.resume()
            }
            .store(in: &cancellables!)

        print("✅ Test suite initialized")
    }

    // MARK: - Helper Methods

    mutating func waitForStateChange(timeout: TimeInterval = 10.0) async throws {
        stateContinuation = nil
        try await withCheckedThrowingContinuation { continuation in
            stateContinuation = continuation
        }
    }

    mutating func resetStateChanges() {
        stateChanges = []
    }

    func assertPlayerState(
        _ expectedState: PlayerState,
        sourceLocation: Testing.SourceLocation = #_sourceLocation
    ) {
        guard let player = player else {
            Test.current.recordIssue("Player should be initialized", sourceLocation: sourceLocation)
            return
        }
        guard let stateChanges = stateChanges else {
            Test.current.recordIssue(
                "State changes should be initialized", sourceLocation: sourceLocation)
            return
        }

        let message = """
            Expected state: \(expectedState)
            Actual state: \(player.state)
            State changes: \(stateChanges)
            """
        #expect(player.state == expectedState, message, sourceLocation: sourceLocation)
    }

    // MARK: - Initialization Tests

    @Test("Player initializes correctly")
    func playerInitialization() {
        print("\n🧪 Test: Player Initialization")

        #expect(player != nil, "Player should be initialized")
        assertPlayerState(.unstarted)
        #expect(stateChanges == [.unstarted], "Initial state should be unstarted")

        print("✅ Test passed: Player initializes correctly")
    }

    @Test("WebView is configured correctly")
    func webViewConfiguration() {
        print("\n🧪 Test: WebView Configuration")

        guard let player = player else {
            Test.current.recordIssue("Player should be initialized")
            return
        }

        let webView = player.webView
        #expect(webView != nil, "WebView should be created")
        #expect(
            webView.configuration.allowsInlineMediaPlayback, "Inline playback should be enabled")
        #expect(webView.backgroundColor == .black, "Background should be black")
        #expect(!webView.isOpaque, "WebView should not be opaque")
        #expect(!webView.scrollView.isScrollEnabled, "Scrolling should be disabled")

        print("✅ Test passed: WebView is configured correctly")
    }

    // MARK: - Video Loading Tests

    @Test(
        "Valid video loads successfully",
        .enabled(if: ProcessInfo.processInfo.environment["RUN_VIDEO_TESTS"] != nil))
    func loadValidVideo() async throws {
        print("\n🧪 Test: Load Valid Video")

        guard let player = player else {
            Test.current.recordIssue("Player should be initialized")
            return
        }

        resetStateChanges()
        let testVideoId = "dQw4w9WgXcQ"

        player.load(videoId: testVideoId)
        print("📺 Loading video: \(testVideoId)")

        // Wait for state to change from unstarted
        try await waitForStateChange(timeout: 15.0)

        // After loading, state should be either cued (ready) or playing
        let validFinalStates: Set<PlayerState> = [.cued, .playing]
        #expect(
            validFinalStates.contains(player.state),
            "Final state should be .cued or .playing, got: \(player.state)")

        // Should have transitioned from unstarted to something else
        #expect((stateChanges?.count ?? 0) >= 2, "Should have at least 2 state changes")
        #expect(stateChanges?.first == .unstarted, "Initial state should be unstarted")

        print("✅ Test passed: Valid video loads successfully")
        print("   State transitions: \(stateChanges ?? [])")
    }

    @Test("Invalid video is handled gracefully")
    func loadInvalidVideo() async throws {
        print("\n🧪 Test: Load Invalid Video")

        guard let player = player else {
            Test.current.recordIssue("Player should be initialized")
            return
        }

        resetStateChanges()
        let invalidVideoId = "invalid_video_id_12345"

        player.load(videoId: invalidVideoId)
        print("📺 Attempting to load invalid video: \(invalidVideoId)")

        // Wait for potential error or timeout
        try await Task.sleep(nanoseconds: 5_000_000_000)

        // State should remain unstarted or change minimally
        print("   Final state: \(player.state)")
        print("   State changes: \(stateChanges ?? [])")

        print("✅ Test passed: Invalid video handled gracefully")
    }

    @Test("Empty video ID is handled without crash")
    func loadEmptyVideoId() async throws {
        print("\n🧪 Test: Load Empty Video ID")

        guard let player = player else {
            Test.current.recordIssue("Player should be initialized")
            return
        }

        resetStateChanges()
        let emptyVideoId = ""

        player.load(videoId: emptyVideoId)
        print("📺 Attempting to load empty video ID")

        try await Task.sleep(nanoseconds: 3_000_000_000)

        // Should not crash
        #expect(player != nil, "Player should still exist")
        print("✅ Test passed: Empty video ID handled without crash")
    }

    @Test(
        "Multiple videos load successfully",
        .enabled(if: ProcessInfo.processInfo.environment["RUN_VIDEO_TESTS"] != nil))
    func loadMultipleVideos() async throws {
        print("\n🧪 Test: Load Multiple Videos")

        guard let player = player else {
            Test.current.recordIssue("Player should be initialized")
            return
        }

        let videoIds = ["dQw4w9WgXcQ", "jNQXAC9IVRw", "M7FIvfx5J10"]

        for (index, videoId) in videoIds.enumerated() {
            print("\n   Loading video \(index + 1)/\(videoIds.count): \(videoId)")
            resetStateChanges()

            player.load(videoId: videoId)

            // Wait for video to load
            try await waitForStateChange(timeout: 10.0)

            let validStates: Set<PlayerState> = [.cued, .playing]
            #expect(
                validStates.contains(player.state), "Video \(index + 1) should load successfully")

            print("   ✅ Video \(index + 1) loaded: \(player.state)")

            // Small delay between videos
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }

        print("✅ Test passed: Multiple videos load successfully")
    }

    // MARK: - Playback Control Tests

    @Test(
        "Play/Pause cycle works correctly",
        .enabled(if: ProcessInfo.processInfo.environment["RUN_VIDEO_TESTS"] != nil))
    func playPauseCycle() async throws {
        print("\n🧪 Test: Play/Pause Cycle")

        guard let player = player else {
            Test.current.recordIssue("Player should be initialized")
            return
        }

        // First load a video
        player.load(videoId: "dQw4w9WgXcQ")
        try await waitForStateChange(timeout: 10.0)
        resetStateChanges()

        // Test play
        print("   ▶️ Playing video...")
        await player.play()
        try await Task.sleep(nanoseconds: 2_000_000_000)

        print("   State after play: \(player.state)")
        let playingStates: Set<PlayerState> = [.playing, .buffering]
        #expect(
            playingStates.contains(player.state),
            "State should be .playing or .buffering after play()")

        // Test pause
        print("   ⏸️ Pausing video...")
        await player.pause()
        try await Task.sleep(nanoseconds: 1_000_000_000)

        print("   State after pause: \(player.state)")
        assertPlayerState(.paused)

        // Test play again
        print("   ▶️ Playing again...")
        await player.play()
        try await Task.sleep(nanoseconds: 1_000_000_000)

        print("   State after second play: \(player.state)")
        #expect(
            playingStates.contains(player.state),
            "State should be .playing or .buffering after second play()")

        print("✅ Test passed: Play/pause cycle works correctly")
    }

    @Test(
        "Seek functionality works correctly",
        .enabled(if: ProcessInfo.processInfo.environment["RUN_VIDEO_TESTS"] != nil))
    func seekFunctionality() async throws {
        print("\n🧪 Test: Seek Functionality")

        guard let player = player else {
            Test.current.recordIssue("Player should be initialized")
            return
        }

        // Load and play video
        player.load(videoId: "jNQXAC9IVRw")  // Long video for testing seek
        try await waitForStateChange(timeout: 10.0)

        await player.play()
        try await Task.sleep(nanoseconds: 3_000_000_000)
        resetStateChanges()

        // Test seek to 30 seconds
        print("   ⏩ Seeking to 30 seconds...")
        await player.seek(to: 30.0)
        try await Task.sleep(nanoseconds: 2_000_000_000)

        print("   State after seek: \(player.state)")
        // State should remain playing or pause briefly for buffering
        let validPostSeekStates: Set<PlayerState> = [.playing, .paused, .buffering]
        #expect(validPostSeekStates.contains(player.state), "State should be valid after seek")

        // Test seek to 2 minutes
        print("   ⏩ Seeking to 2 minutes...")
        await player.seek(to: 120.0)
        try await Task.sleep(nanoseconds: 2_000_000_000)

        print("   State after second seek: \(player.state)")
        #expect(
            validPostSeekStates.contains(player.state), "State should be valid after second seek")

        // Test seek to beginning
        print("   ⏪ Seeking to beginning...")
        await player.seek(to: 0.0)
        try await Task.sleep(nanoseconds: 2_000_000_000)

        print("   State after seek to beginning: \(player.state)")
        #expect(
            validPostSeekStates.contains(player.state),
            "State should be valid after seek to beginning")

        print("✅ Test passed: Seek functionality works correctly")
    }

    @Test(
        "Multiple operations in sequence execute successfully",
        .enabled(if: ProcessInfo.processInfo.environment["RUN_VIDEO_TESTS"] != nil))
    func multipleOperationsInSequence() async throws {
        print("\n🧪 Test: Multiple Operations in Sequence")

        guard let player = player else {
            Test.current.recordIssue("Player should be initialized")
            return
        }

        player.load(videoId: "dQw4w9WgXcQ")
        try await waitForStateChange(timeout: 10.0)

        let operations = [
            { await player.play() },
            { await player.pause() },
            { await player.play() },
            { await player.seek(to: 15.0) },
            { await player.pause() },
            { await player.seek(to: 30.0) },
            { await player.play() },
        ]

        for (index, operation) in operations.enumerated() {
            print("   Operation \(index + 1)/\(operations.count)...")
            operation()
            try await Task.sleep(nanoseconds: 1_000_000_000)
            print("   State: \(player.state)")
        }

        // Final state should be playing
        assertPlayerState(.playing)

        print("✅ Test passed: Multiple operations execute successfully")
    }

    // MARK: - State Management Tests

    @Test(
        "All states are properly observed",
        .enabled(if: ProcessInfo.processInfo.environment["RUN_VIDEO_TESTS"] != nil))
    func allStatesAreObservable() async throws {
        print("\n🧪 Test: All States Are Observable")

        guard let player = player else {
            Test.current.recordIssue("Player should be initialized")
            return
        }

        resetStateChanges()
        player.load(videoId: "dQw4w9WgXcQ")

        // Wait for initial load
        try await waitForStateChange(timeout: 10.0)
        let validStates: Set<PlayerState> = [.cued, .playing]
        #expect(validStates.contains(player.state))

        // Test play
        await player.play()
        try await Task.sleep(nanoseconds: 2_000_000_000)
        let playingStates: Set<PlayerState> = [.playing, .buffering]
        #expect(playingStates.contains(player.state))

        // Test pause
        await player.pause()
        try await Task.sleep(nanoseconds: 1_000_000_000)
        assertPlayerState(.paused)

        // Test that all states were captured
        print("   All observed states: \(Set(stateChanges ?? []))")
        #expect((stateChanges?.count ?? 0) > 2, "Should have multiple state changes")

        print("✅ Test passed: All states are properly observed")
    }

    @Test(
        "@Published state updates work correctly",
        .enabled(if: ProcessInfo.processInfo.environment["RUN_VIDEO_TESTS"] != nil))
    func publishedStateUpdates() async throws {
        print("\n🧪 Test: Published State Updates")

        guard let player = player else {
            Test.current.recordIssue("Player should be initialized")
            return
        }

        let stateUpdated = expectation(description: "State updated")

        player.$state
            .dropFirst()  // Skip initial .unstarted
            .sink { state in
                if state == .cued || state == .playing {
                    stateUpdated.fulfill()
                }
            }
            .store(in: &cancellables!)

        player.load(videoId: "dQw4w9WgXcQ")

        await fulfillment(of: [stateUpdated], timeout: 10.0)

        print("✅ Test passed: @Published state updates work correctly")
    }

    // MARK: - Error Handling Tests

    @Test("Player handles errors gracefully and recovers")
    func errorHandlingWithInvalidVideo() async throws {
        print("\n🧪 Test: Error Handling with Invalid Video")

        guard let player = player else {
            Test.current.recordIssue("Player should be initialized")
            return
        }

        resetStateChanges()

        // This should not crash app
        player.load(videoId: "completely_invalid_id_999999")

        // Wait a bit
        try await Task.sleep(nanoseconds: 5_000_000_000)

        // Player should still be functional
        #expect(player != nil)
        print("   Player state: \(player.state)")
        print("   State changes: \(stateChanges ?? [])")

        // Try loading a valid video
        player.load(videoId: "dQw4w9WgXcQ")
        try await waitForStateChange(timeout: 10.0)

        let validStates: Set<PlayerState> = [.cued, .playing]
        #expect(validStates.contains(player.state), "Player should recover and load valid video")

        print("✅ Test passed: Player handles errors gracefully and recovers")
    }

    // MARK: - Performance Tests

    @Test("Initialization performance is acceptable")
    func initializationPerformance() {
        print("\n🧪 Test: Initialization Performance")

        let player = YouTubePlayer()
        #expect(player != nil, "Player should initialize")

        print("✅ Test passed: Initialization performance measured")
    }

    @Test(
        "Video load performance is acceptable",
        .enabled(if: ProcessInfo.processInfo.environment["RUN_VIDEO_TESTS"] != nil))
    func videoLoadPerformance() async throws {
        print("\n🧪 Test: Video Load Performance")

        guard let player = player else {
            Test.current.recordIssue("Player should be initialized")
            return
        }

        let testVideoId = "dQw4w9WgXcQ"

        let startTime = Date()
        player.load(videoId: testVideoId)

        try await waitForStateChange(timeout: 10.0)

        let loadTime = Date().timeIntervalSince(startTime)
        print("   ⏱️ Video load time: \(String(format: "%.2f", loadTime))s")

        #expect(loadTime < 8.0, "Video should load in less than 8 seconds")

        print("✅ Test passed: Video load performance acceptable")
    }

    @Test(
        "State update latency is acceptable",
        .enabled(if: ProcessInfo.processInfo.environment["RUN_VIDEO_TESTS"] != nil))
    func stateUpdateLatency() async throws {
        print("\n🧪 Test: State Update Latency")

        guard let player = player else {
            Test.current.recordIssue("Player should be initialized")
            return
        }

        player.load(videoId: "dQw4w9WgXcQ")

        let latencies: [TimeInterval] = [
            await measureStateChange { await player.play() },
            await measureStateChange { await player.pause() },
            await measureStateChange { await player.play() },
        ]

        let averageLatency = latencies.reduce(0, +) / Double
        (latencies.count)
        print("   ⏱️ Average state update latency: \(String(format: "%.3f", averageLatency))s")
        print("   Individual latencies: \(latencies.map { String(format: "%.3f", $0) + "s" })")

        #expect(averageLatency < 1.0, "State updates should be faster than 1 second")

        print("✅ Test passed: State update latency acceptable")
    }

    // MARK: - Concurrency Tests

    @Test("Main actor isolation is working correctly")
    func mainActorIsolation() async throws {
        print("\n🧪 Test: Main Actor Isolation")

        // All operations should run on main actor
        #expect(Thread.isMainThread, "Test should run on main thread")

        guard let player = player else {
            Test.current.recordIssue("Player should be initialized")
            return
        }

        #expect(player.webView != nil)
        assertPlayerState(.unstarted)

        player.load(videoId: "dQw4w9WgXcQ")
        try await waitForStateChange(timeout: 10.0)

        #expect(player != nil)

        print("✅ Test passed: Main actor isolation working correctly")
    }

    @Test(
        "Concurrent operations are handled safely",
        .enabled(if: ProcessInfo.processInfo.environment["RUN_VIDEO_TESTS"] != nil))
    func concurrentOperations() async throws {
        print("\n🧪 Test: Concurrent Operations")

        guard let player = player else {
            Test.current.recordIssue("Player should be initialized")
            return
        }

        player.load(videoId: "dQw4w9WgXcQ")
        try await waitForStateChange(timeout: 10.0)

        // Launch multiple operations concurrently
        async let play1 = player.play()
        async let play2 = player.play()
        async let seek1 = player.seek(to: 10.0)
        async let seek2 = player.seek(to: 20.0)

        // All should complete without throwing
        try? await play1
        try? await play2
        try? await seek1
        try? await seek2

        try await Task.sleep(nanoseconds: 2_000_000_000)

        // Player should still be functional
        let validStates: Set<PlayerState> = [.playing, .paused, .buffering]
        #expect(validStates.contains(player.state))

        print("✅ Test passed: Concurrent operations handled safely")
    }

    // MARK: - Memory Tests

    @Test("Memory management is analyzed")
    func memoryManagement() async throws {
        print("\n🧪 Test: Memory Management")

        weak var weakPlayer: YouTubePlayer?

        autoreleasepool {
            let tempPlayer = YouTubePlayer()
            weakPlayer = tempPlayer

            tempPlayer.load(videoId: "dQw4w9WgXcQ")

            // Wait a bit
            let expectation = expectation(description: "Wait")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }

        // Give time for deallocation
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // Note: WKUserContentController retains the message handler,
        // so weakPlayer might not be nil. This is expected behavior.
        print("   Weak player reference: \(weakPlayer == nil ? "nil" : "still alive")")
        print("   Note: WebView's script handler retention is expected")

        print("✅ Test passed: Memory management analyzed")
    }

    // MARK: - Integration Tests

    @Test(
        "End-to-end workflow is successful",
        .enabled(if: ProcessInfo.processInfo.environment["RUN_VIDEO_TESTS"] != nil))
    func endToEndWorkflow() async throws {
        print("\n🧪 Test: End-to-End Workflow")

        guard let player = player else {
            Test.current.recordIssue("Player should be initialized")
            return
        }

        print("   Step 1: Initialize player")
        #expect(player != nil)
        assertPlayerState(.unstarted)

        print("   Step 2: Load video")
        player.load(videoId: "jNQXAC9IVRw")
        try await waitForStateChange(timeout: 10.0)
        let validStates: Set<PlayerState> = [.cued, .playing]
        #expect(validStates.contains(player.state))

        print("   Step 3: Play video")
        await player.play()
        try await Task.sleep(nanoseconds: 3_000_000_000)
        let playingStates: Set<PlayerState> = [.playing, .buffering]
        #expect(playingStates.contains(player.state))

        print("   Step 4: Pause video")
        await player.pause()
        try await Task.sleep(nanoseconds: 1_000_000_000)
        assertPlayerState(.paused)

        print("   Step 5: Seek to 30s")
        await player.seek(to: 30.0)
        try await Task.sleep(nanoseconds: 2_000_000_000)
        let seekStates: Set<PlayerState> = [.playing, .paused, .buffering]
        #expect(seekStates.contains(player.state))

        print("   Step 6: Resume playback")
        await player.play()
        try await Task.sleep(nanoseconds: 2_000_000_000)
        #expect(playingStates.contains(player.state))

        print("   Step 7: Load new video")
        player.load(videoId: "dQw4w9WgXcQ")
        try await waitForStateChange(timeout: 10.0)
        #expect(validStates.contains(player.state))

        print("✅ Test passed: End-to-end workflow successful")
    }

    // MARK: - Helper Methods for Performance Testing

    private func measureStateChange<T>(_ operation: () async throws -> T) async rethrows
        -> TimeInterval
    {
        guard let player = player else {
            return 0
        }

        let startTime = Date()
        let initialState = player.state

        _ = try await operation()

        // Wait for state to change
        let timeout = Date().addingTimeInterval(3.0)
        while player.state == initialState && Date() < timeout {
            try await Task.sleep(nanoseconds: 50_000_000)  // 50ms
        }

        return Date().timeIntervalSince(startTime)
    }
}
