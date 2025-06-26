//
//  EditingActionsPanel.swift
//  PKEditor
//
//  Created by Luca Rocchi on 25/06/25.
//


import SwiftUI

struct EditingActionsPanel: View {
    // Callbacks for the button actions
    var onRotateLeft: () -> Void
    var onRotateRight: () -> Void
    
    // You can add more callbacks here for future buttons

    var body: some View {
        HStack(spacing: 25) { // Adjust spacing as needed
            
            // Rotate Left Button
            Button(action: onRotateLeft) {
                Image(systemName: "rotate.left")
                    .font(.headline)
            }
            
            // Rotate Right Button
            Button(action: onRotateRight) {
                Image(systemName: "rotate.right")
                    
            }
            
            // You could add more buttons here, for example:
            // Button(action: { ... }) { Image(systemName: "flip.horizontal.fill") }
            
        }
        .font(.subheadline) // Sets a nice size for all icons
        .foregroundColor(.primary) // Adapts to light/dark mode
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
        .background(.thinMaterial) // Modern "frosted glass" effect
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.15), radius: 5, y: 2)
    }
}

