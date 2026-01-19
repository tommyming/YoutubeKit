import Combine
import UIKit
import WebKit

public class YouTubePlayerUIView: UIView {

    // MARK: - Properties

    public let player: YouTubePlayer
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// Initializes the view with a new player instance.
    public init() {
        self.player = YouTubePlayer()
        super.init(frame: .zero)
        setupView()
    }

    /// Initializes the view with an existing player instance.
    /// - Parameter player: The player instance to use.
    public init(player: YouTubePlayer) {
        self.player = player
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        self.player = YouTubePlayer()
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .black

        let webView = player.webView
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
