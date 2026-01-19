import SwiftUI
import WebKit

public struct YouTubePlayerView: UIViewRepresentable {

    // MARK: - Properties

    @ObservedObject public var player: YouTubePlayer

    // MARK: - Initialization

    public init(player: YouTubePlayer) {
        self.player = player
    }

    // MARK: - UIViewRepresentable

    public func makeUIView(context: Context) -> WKWebView {
        return player.webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        // Leave empty to prevent reloading the webview on state changes
    }
}
