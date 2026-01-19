# YouTubeKit

**YouTubeKit** is a modern, lightweight, and strictly-typed Swift library for embedding YouTube videos in iOS applications. It is designed to feel like a native Apple framework, offering a "Black Box" engine approach that abstracts away the complexity of the YouTube IFrame API.

## Features

- 🚀 **Modern Swift**: Built with strict concurrency safety using `async/await`.
- 📱 **iOS 13+ Support**: Includes a concurrency shim for older iOS versions.
- 🔒 **Privacy First**: Includes a `PrivacyInfo.xcprivacy` manifest.
- 🛠 **System-Level Feel**: Strictly typed API with no loose strings or untyped dictionaries in the public interface.
- 📦 **Zero Assets**: No bundled HTML/CSS files to avoid CORS or file-loading issues.

## Requirements

- iOS 13.0+
- Swift 5.5+
- Xcode 13.0+

## Installation

### Swift Package Manager

Add `YouTubeKit` to your project via Swift Package Manager:

1. In Xcode, go to **File > Add Packages...**
2. Enter the repository URL.
3. Select **YouTubeKit** and add it to your target.

## Usage

### 1. Initialize the Player

Create a `YouTubePlayer` instance. This class is an `@MainActor` isolated `ObservableObject`.

```swift
import YouTubeKit
import SwiftUI

class ViewModel: ObservableObject {
    let player = YouTubePlayer()
    
    func loadVideo() {
        player.load(videoId: "dQw4w9WgXcQ")
    }
}
```

### 2. Add the View

Use `YouTubePlayerView` in your SwiftUI hierarchy.

```swift
struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            YouTubePlayerView(player: viewModel.player)
                .aspectRatio(16/9, contentMode: .fit)
                .cornerRadius(12)
            
            HStack {
                Button("Load") {
                    viewModel.loadVideo()
                }
                Button("Play") {
                    Task { await viewModel.player.play() }
                }
                Button("Pause") {
                    Task { await viewModel.player.pause() }
                }
            }
        }
    }
}
```

### 3. Control Playback

All playback controls are `async` functions to ensure thread safety and predictable execution order.

```swift
// Play
await player.play()

// Pause
await player.pause()

// Seek
await player.seek(to: 30.5) // Seek to 30.5 seconds
```

### 4. Observe State

The `YouTubePlayer` publishes its state via the `state` property, which maps directly to YouTube's player states.

```swift
// Valid states: .unstarted, .ended, .playing, .paused, .buffering, .cued
switch player.state {
case .playing:
    print("Video is playing")
case .buffering:
    print("Buffering...")
default:
    break
}
```

## Privacy

YouTubeKit includes a `PrivacyInfo.xcprivacy` file to comply with Apple's privacy manifest requirements.
- **Tracking**: Disabled (`NSPrivacyTracking` is false).
- **Accessed APIs**: None.
- **Collected Data**: None.

## Architecture

YouTubeKit treats the `WKWebView` as an internal engine. It injects a static HTML template that bridges the YouTube IFrame API to native Swift code using `WKScriptMessageHandler`. This ensures:
1.  **Safety**: No direct JavaScript string manipulation by the consumer.
2.  **Performance**: Minimal overhead with no external file loading.
3.  **Reliability**: `origin` and `playsinline` are strictly enforced to prevent playback errors.

## License

This library is released under the Apache 2.0 License.
