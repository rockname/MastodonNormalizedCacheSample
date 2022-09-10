import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let request: URLRequest
    let navigationDelegate: WKNavigationDelegate?

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.navigationDelegate = navigationDelegate
        uiView.load(request)
    }
}
