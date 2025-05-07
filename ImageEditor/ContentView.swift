//
//  ContentView.swift
//  ImageEditor
//
//  Created by Roberto Santacroce on 7/5/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        ImageEditorContainer()
            .edgesIgnoringSafeArea(.all)
    }
}

struct ImageEditorContainer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ImageEditorViewController {
        return ImageEditorViewController()
    }

    func updateUIViewController(_ uiViewController: ImageEditorViewController, context: Context) {}
}
