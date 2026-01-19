import WebKit

extension WKWebView {
    /// Evaluates the given JavaScript string.
    /// - Parameter script: The JavaScript string to evaluate.
    /// - Returns: The result of the script evaluation.
    /// - Throws: An error if the script evaluation fails.
    /// - Note: This is a shim to support async/await on iOS 13+ as the native async method is available only on iOS 15+.
    @MainActor
    func evaluate(_ script: String) async throws -> Any? {
        return try await withCheckedThrowingContinuation { continuation in
            self.evaluateJavaScript(script) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result)
                }
            }
        }
    }
}
