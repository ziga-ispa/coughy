import SwiftUI
import WebKit

/// Renders an SVG file from the main bundle using WKWebView with a transparent background.
struct SVGImageView: UIViewRepresentable {
    let resourceName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        load(in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    private func load(in webView: WKWebView) {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "svg"),
              let svg = try? String(contentsOf: url, encoding: .utf8) else { return }

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <style>
        html,body{margin:0;padding:0;background:transparent;}
        svg{width:100%;height:auto;display:block;}
        </style>
        </head>
        <body>\(svg)</body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
    }
}
