//
//  ContentView.swift
//  DollarToday
//
//  Created by Alejandro Cesar Tami on 21/04/2023.
//

import Combine
import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var viewModel = DollarWebViewModel()
    
    var body: some View {
        #if os(macOS)
            WebView(html: $viewModel.blue)
        #endif
        EmptyView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

final class DollarWebViewModel: ObservableObject {
    @Published var blue: String = """
        <div><iframe style="width:320px;height:260px;border-radius:10px;box-shadow:2px 4px 4px rgb(0 0 0 / 25%);display:flex;justify-content:center;border:1px solid #bcbcbc" src="https://dolarhoy.com/i/cotizaciones/dolar-blue" frameborder="0"></iframe></div>
    """
  
}

#if os(macOS)
struct WebView: View {
    @Binding var html: String
    
    var body: some View {
        WebViewWrapper(html: html)
    }
}
#endif

#if os(macOS)
struct WebViewWrapper: NSViewRepresentable {
    let html: String
    
    func makeNSView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(html, baseURL: nil)
    }
}
#endif
