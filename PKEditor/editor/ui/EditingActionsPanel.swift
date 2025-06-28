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
    
    @ObservedObject var model = EditorModel.shared
    // You can add more callbacks here for future buttons

    private var backgroundColorBinding: Binding<Color> {
            Binding<Color>(
                // GET: Convert the model's UIColor to a SwiftUI Color
                get: { Color(self.model.backgroundColor) },
                
                // SET: Convert the ColorPicker's new Color back to a UIColor
                set: { newColor in
                    // We need to get the UIColor components from the new SwiftUI Color.
                    // This requires a bit of code.
                    let uiColor = UIColor(newColor)
                    self.model.backgroundColor = uiColor
                    
                }
            )
        }

    
    var body: some View {
        HStack(spacing: 25) { // Adjust spacing as needed
            if let selectedStroke = model.selectedStroke {
                // Rotate Left Button
                Button(action: onRotateLeft) {
                 Image(systemName: "rotate.left")
                 
                 }
                 
                 // Rotate Right Button
                 Button(action: onRotateRight) {
                 Image(systemName: "rotate.right")
                 
                 }
            }
            
            ColorPicker("Background", selection: backgroundColorBinding, supportsOpacity: true)
                              .labelsHidden()
                              
                              
                              
                              
            
            // You could add more buttons here, for example:
            // Button(action: { ... }) { Image(systemName: "flip.horizontal.fill") }
            
        }
        .font(.title3) // Sets a nice size for all icons
        .foregroundColor(.primary) // Adapts to light/dark mode
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial) // Modern "frosted glass" effect
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.15), radius: 5, y: 2)
        
    }
}

