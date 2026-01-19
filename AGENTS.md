# AGENTS.md - YouTubeKit Refactoring Plan

## 1. Project Overview
**Goal:** Rewrite a legacy Objective-C YouTube library into a modern, system-level Swift library named **YouTubeKit**.  
**Philosophy:** Treat the library as a "Black Box Engine." The API must be strictly typed, concurrency-safe, and feel like a native Apple framework (e.g., AVKit).  
**Target:** iOS 13+ (Strict Support).  
**Distribution:** Swift Package Manager (SPM) only.

## 2. Technical Constraints
1.  **Strict Concurrency:** Use `async/await` for all asynchronous operations.
2.  **iOS 13 Compatibility:** Since native `WKWebView.evaluateJavaScript(_:) async` is iOS 15+, you MUST implement a `withCheckedThrowingContinuation` shim for iOS 13 support.
3.  **No Assets:** Do not bundle `.html` files. All HTML must be embedded as static Swift strings to prevent CORS/File-loading issues.
4.  **Privacy:** Include a `PrivacyInfo.xcprivacy` file.
5.  **Naming:** The namespace is `YouTubeKit`. The bridge name in JS is `youTubeKitBridge`.

## 3. Directory Structure
Ensure the project follows this exact structure:
```text
YouTubeKit/
├── Package.swift
├── Sources/
│   └── YouTubeKit/
│       ├── YouTubePlayer.swift       # The Engine (Main Actor)
│       ├── YouTubePlayerView.swift   # The UI (SwiftUI)
│       ├── Core/
│       │   ├── HTMLTemplate.swift    # Static HTML Generator
│       │   └── PlayerEnums.swift     # State & Error Definitions
│       ├── Extensions/
│       │   └── WKWebView+Async.swift # iOS 13 Shim
│       └── PrivacyInfo.xcprivacy
```

## 4. Execution Stages

### Stage 1: Infrastructure Setup
**Task:** Initialize the package and clean up.
*   Run `swift package init --type library`.
*   Delete any default test files or Objective-C headers if present.
*   Update `Package.swift`:
    *   Set platforms: `[.iOS(.v13)]`.
    *   Name the library `YouTubeKit`.
    *   Ensure strict Swift 5.5+ settings.

### Stage 2: Core Data Types
**Task:** Define the "Language" of the library before the logic.  
**File:** `Sources/YouTubeKit/Core/PlayerEnums.swift`

*   Create `public enum PlayerState: Int (CaseIterable)`:
    *   Map YouTube values: `unstarted` (-1), `ended` (0), `playing` (1), `paused` (2), `buffering` (3), `cued` (5).
*   Create `public enum PlayerError: Error`:
    *   Cases: `domainRestricted`, `videoNotFound`, `html5Error`, `unknown`.

### Stage 3: The HTML Engine
**Task:** Create the static HTML generator.  
**File:** `Sources/YouTubeKit/Core/HTMLTemplate.swift`

*   Create a static function `generate(videoId: String) -> String`.
*   **CRITICAL REQUIREMENTS:**
    *   Embed the `https://www.youtube.com/iframe_api` script.
    *   In `YT.Player` config, set `origin: 'https://www.youtube.com'`.
    *   In `YT.Player` config, set `playsinline: 1`.
    *   Implement JS callbacks that post messages to `window.webkit.messageHandlers.youTubeKitBridge`.
    *   Events to handle: `onReady`, `onStateChange`, `onError`.

### Stage 4: The Concurrency Shim (iOS 13)
**Task:** Enable async/await on older iOS versions.  
**File:** `Sources/YouTubeKit/Extensions/WKWebView+Async.swift`

*   Extend `WKWebView`.
*   Create function: `@MainActor func evaluate(_ script: String) async throws -> Any?`.
*   **Implementation:** Use `withCheckedThrowingContinuation` to wrap the standard `evaluateJavaScript` completion handler.

### Stage 5: The Player Engine (The Actor)
**Task:** Build the main controller class.  
**File:** `Sources/YouTubeKit/YouTubePlayer.swift`

*   Define `public class YouTubePlayer: NSObject, ObservableObject`.
*   Annotate with `@MainActor`.
*   **Properties:**
    *   `@Published public var state: PlayerState`
    *   `internal let webView: WKWebView`
*   **Init:**
    *   Config `allowsInlineMediaPlayback = true`.
    *   Add `WKScriptMessageHandler` with name `"youTubeKitBridge"`.
    *   Set background color to clear/black.
*   **Methods (Async):**
    *   `load(videoId: String)`: Calls `HTMLTemplate` and `webView.loadHTMLString(..., baseURL: URL(string: "https://www.youtube.com"))`.
    *   `play()`, `pause()`, `seek(to:)`: Use the evaluate shim from Stage 4.
*   **Extension:** Implement `WKScriptMessageHandler` to update state based on JS events.

### Stage 6: The UI Layer
**Task:** Create the SwiftUI wrapper.  
**File:** `Sources/YouTubeKit/YouTubePlayerView.swift`

*   Define `struct YouTubePlayerView: UIViewRepresentable`.
*   **Properties:** `@ObservedObject var player: YouTubePlayer`.
*   `makeUIView`: Return `player.webView`.
*   `updateUIView`: Leave empty (do not reload webview on state changes).

### Stage 7: Privacy Compliance
**Task:** Add the manifest.  
**File:** `Sources/YouTubeKit/PrivacyInfo.xcprivacy`

*   Add the standard XML structure.
*   Set `NSPrivacyTracking` to `false`.
*   Set `NSPrivacyAccessedAPITypes` to an empty array.

## 5. Final Verification Checklist
*   [x] Does `Package.swift` require iOS 13?
*   [x] Is `YouTubePlayer` an `@MainActor` class?
*   [x] Is the HTML loaded with a specific `baseURL` (not nil)?
*   [x] Is the JS Bridge name consistent (`youTubeKitBridge`) in both Swift and HTML?
*   [x] Are there ZERO calls to `completionHandler` in the public API (only async/await)?