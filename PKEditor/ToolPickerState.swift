//
//  ToolPickerState.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//


import Foundation
import PencilKit
import SwiftUI // For Color conversion if needed for UserDefaults

// MARK: - Extension for PKInk to be Codable (for saving color)
extension PKInk.InkType: Codable {} // Make InkType Codable


// *** ADD THIS EXTENSION ***
// MARK: - Extension for PKEraserTool.EraserType to be Codable
//extension PKEraserTool.EraserType: Codable {}


extension UIColor {
    func encode() -> Data? {
        do {
            return try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: true)
        } catch {
            print("Error archiving UIColor: \(error)")
            return nil
        }
    }

    static func decode(from data: Data) -> UIColor? {
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)
        } catch {
            print("Error unarchiving UIColor: \(error)")
            return nil
        }
    }
}

// MARK: - PKToolPicker State Model (Corrected Codable Conformance for EraserType)
// MARK: - PKToolPicker State Model (Final Corrected Codable Conformance)
struct ToolPickerState: Codable, Equatable{
    var inkType: PKInk.InkType = .pen
    var colorData: Data? = UIColor.black.encode()
    var width: CGFloat = 1.0
    
    // --- CHANGE STARTS HERE ---
    // Store eraser type as a String representation
    var eraserTypeString: String = "vector" // Default to "vector"
    var isRulerActive: Bool = false
    var selectedToolIdentifier: String?

    // Computed property to get the actual PKEraserTool.EraserType
    var eraserType: PKEraserTool.EraserType {
        get {
            // Convert string back to EraserType
            switch eraserTypeString {
            case "vector": return .vector
            case "bitmap": return .bitmap
            default: return .vector // Fallback
            }
        }
        set {
            // Convert EraserType to string for storage
            switch newValue {
            case .vector: eraserTypeString = "vector"
            case .bitmap: eraserTypeString = "bitmap"
            @unknown default: eraserTypeString = "vector" // Handle future cases gracefully
            }
        }
    }
    // --- CHANGE ENDS HERE ---

    var color: UIColor {
        if let data = colorData, let decodedColor = UIColor.decode(from: data) {
            return decodedColor
        }
        return .black
    }

    // MARK: - Custom Codable Implementation

    enum CodingKeys: String, CodingKey {
        case inkType
        case colorData
        case width
        case eraserTypeString // Use this key for encoding/decoding the string
        case isRulerActive
        case selectedToolIdentifier
    }

    init() {
          // This initializer uses the default values declared for each property.
          // No explicit assignments needed here if all properties already have default values.
          // It simply makes ToolPickerState() callable.
      }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.inkType = try container.decode(PKInk.InkType.self, forKey: .inkType)
        self.colorData = try container.decodeIfPresent(Data.self, forKey: .colorData)
        self.width = try container.decode(CGFloat.self, forKey: .width)
        
        // --- CHANGE STARTS HERE ---
        // Decode the string representation
        self.eraserTypeString = try container.decode(String.self, forKey: .eraserTypeString)
        // --- CHANGE ENDS HERE ---

        self.isRulerActive = try container.decode(Bool.self, forKey: .isRulerActive)
        self.selectedToolIdentifier = try container.decodeIfPresent(String.self, forKey: .selectedToolIdentifier)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(inkType, forKey: .inkType)
        try container.encodeIfPresent(colorData, forKey: .colorData)
        try container.encode(width, forKey: .width)
        
        // --- CHANGE STARTS HERE ---
        // Encode the string representation
        try container.encode(eraserTypeString, forKey: .eraserTypeString)
        // --- CHANGE ENDS HERE ---

        try container.encode(isRulerActive, forKey: .isRulerActive)
        try container.encodeIfPresent(selectedToolIdentifier, forKey: .selectedToolIdentifier)
    }
}

/*
// MARK: - StackedCanvasExample (Parent View)
struct StackedCanvasExample: View {
    @State private var drawing1: PKDrawing = PKDrawing()
    @State private var drawing2: PKDrawing = PKDrawing()
    @State private var drawing3: PKDrawing = PKDrawing()

    @State private var activeCanvas: Int = 1
    
    @State private var toolPicker: PKToolPicker? = nil
    
    // *** NEW: State for the tool picker's current settings ***
    // Use AppStorage for persistence across app launches
    @AppStorage("lastToolPickerState")
    private var storedToolPickerStateData: Data?

    @State private var toolPickerState: ToolPickerState = ToolPickerState()


    var body: some View {
        VStack {
            Picker("Active Canvas", selection: $activeCanvas) {
                Text("Canvas 1").tag(1)
                Text("Canvas 2").tag(2)
                Text("Canvas 3").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()

            ZStack {
                Color.gray.opacity(0.1)
                    .ignoresSafeArea()

                MyCanvasView(
                    drawing: $drawing1,
                    toolPicker: activeCanvas == 1 ? $toolPicker : .constant(nil),
                    toolPickerState: $toolPickerState // Pass the state binding
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(activeCanvas == 1)
                .zIndex(1)

                MyCanvasView(
                    drawing: $drawing2,
                    toolPicker: activeCanvas == 2 ? $toolPicker : .constant(nil),
                    toolPickerState: $toolPickerState // Pass the state binding
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(activeCanvas == 2)
                .zIndex(2)

                MyCanvasView(
                    drawing: $drawing3,
                    toolPicker: activeCanvas == 3 ? $toolPicker : .constant(nil),
                    toolPickerState: $toolPickerState // Pass the state binding
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(activeCanvas == 3)
                .zIndex(3)
            }
            .onAppear {
                // Initialize toolPicker and load saved state
                if toolPicker == nil {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        toolPicker = PKToolPicker.shared(for: window)
                    }
                }
                // Load state from UserDefaults
                if let data = storedToolPickerStateData {
                    if let loadedState = try? JSONDecoder().decode(ToolPickerState.self, from: data) {
                        toolPickerState = loadedState
                    }
                }
            }
            .onDisappear {
                // Save current state to UserDefaults
                if let encoded = try? JSONEncoder().encode(toolPickerState) {
                    storedToolPickerStateData = encoded
                }
                toolPicker?.setVisible(false, forFirstResponder: nil)
                // Remove all observers for safety.
                // In a real app, you might maintain a list of specific observers to remove.
                // PKToolPicker doesn't offer a clean way to remove all observers.
                // For simplicity, for an app closing, this is often okay.
            }
            .onChange(of: toolPickerState) { oldState, newState in
                // This will trigger when the toolPickerState updates, ensuring
                // it gets saved back to AppStorage.
                if let encoded = try? JSONEncoder().encode(newState) {
                    storedToolPickerStateData = encoded
                }
            }
        }
    }
}
*/
