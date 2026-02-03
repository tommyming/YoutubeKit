import Combine
import SwiftUI
import YouTubeKit

@main
struct TestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class ViewModel: ObservableObject {
    @Published var player: YouTubePlayer
    @Published var videoId: String = "dQw4w9WgXcQ"  // Rick Roll video for testing
    @Published var statusMessage: String = "Ready to load"
    @Published var isLoading: Bool = false

    init() {
        self.player = YouTubePlayer()
        setupStateObserver()
    }

    private func setupStateObserver() {
        player.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateStatus(for: state)
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    func loadVideo() {
        statusMessage = "Loading video..."
        isLoading = true
        player.load(videoId: videoId)
    }

    func playVideo() {
        Task { @MainActor in
            do {
                await player.play()
                statusMessage = "Playing video"
            } catch {
                statusMessage = "Error playing: \(error)"
            }
        }
    }

    func pauseVideo() {
        Task { @MainActor in
            do {
                await player.pause()
                statusMessage = "Paused"
            } catch {
                statusMessage = "Error pausing: \(error)"
            }
        }
    }

    func seekTo(seconds: Double) {
        Task { @MainActor in
            do {
                await player.seek(to: seconds)
                statusMessage = "Seeked to \(seconds)s"
            } catch {
                statusMessage = "Error seeking: \(error)"
            }
        }
    }

    private func updateStatus(for state: PlayerState) {
        isLoading = false
        switch state {
        case .unstarted:
            statusMessage = "Video unstarted"
        case .ended:
            statusMessage = "Video ended"
        case .playing:
            statusMessage = "Playing 🎵"
        case .paused:
            statusMessage = "Paused ⏸️"
        case .buffering:
            statusMessage = "Buffering..."
        case .cued:
            statusMessage = "Video cued and ready"
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("YouTubeKit Test App")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Status: \(viewModel.statusMessage)")
                .font(.headline)
                .foregroundColor(.secondary)

            // YouTube Player View
            YouTubePlayerView(player: viewModel.player)
                .frame(height: 200)
                .cornerRadius(12)
                .shadow(radius: 5)
                .overlay(
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                        }
                    }
                )

            // Video ID Input
            HStack {
                Text("Video ID:")
                    .frame(width: 80, alignment: .leading)
                TextField("Enter video ID", text: $viewModel.videoId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
            }
            .padding(.horizontal)

            // Control Buttons
            VStack(spacing: 12) {
                Button(action: viewModel.loadVideo) {
                    Label("Load Video", systemImage: "arrow.down.doc")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.videoId.isEmpty)

                HStack(spacing: 20) {
                    Button(action: viewModel.playVideo) {
                        Label("Play", systemImage: "play.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.player.state != .paused && viewModel.player.state != .cued)

                    Button(action: viewModel.pauseVideo) {
                        Label("Pause", systemImage: "pause.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.player.state != .playing)
                }

                Button(action: { viewModel.seekTo(seconds: 30) }) {
                    Label("Seek to 30s", systemImage: "forward.fill")
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            // Info Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Test Instructions:")
                    .font(.headline)
                Text("1. Enter a YouTube video ID or use the default")
                Text("2. Tap 'Load Video' to load the player")
                Text("3. Use Play/Pause buttons to control playback")
                Text("4. Observe the status messages above")
                Text("5. Try seeking to different timestamps")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
}
