//
//  TextInput.swift
//  PKEditor
//
//  Created by Luca Rocchi on 21/06/25.
//

import SwiftUI
/*
 struct TextInput: View {
 @State private var currentPosition: CGSize = .zero
 @State private var newPosition: CGSize = .zero
 @State var inputText = ""
 
 
 var body: some View {
 TextField("Type some text here...", text: $inputText,axis: .vertical)
 .font(.title2)
 
 .multilineTextAlignment(.leading)
 .lineLimit(nil)
 
 .frame(minWidth:200,maxWidth: .infinity)
 .padding(20)
 .border(Color.accentColor, width: 2)
 .padding(20)
 .offset(
 x: currentPosition.width,
 y: currentPosition.height)
 .gesture(DragGesture()
 .onChanged { value in
 currentPosition = CGSize(
 width: value.translation.width + newPosition.width,
 height: value.translation.height + newPosition.height)
 }
 .onEnded { value in
 currentPosition = CGSize(
 width: value.translation.width + newPosition.width,
 height: value.translation.height + newPosition.height)
 newPosition = currentPosition
 }
 )
 }
 }
 
 */
struct TextInput: View {
    @State private var currentPosition: CGSize = .zero
    @State private var newPosition: CGSize = .zero
    @State var inputText = ""
    
    // --- Passaggio 1: Aggiungi una variabile di stato per il focus ---
    // Questa variabile terrà traccia di quale campo di testo è attivo.
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        TextField("Type some text here...", text: $inputText, axis: .vertical)
            .font(.title2)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .frame(minWidth:200, maxWidth: .infinity)
            .padding(20)
            .border(Color.accentColor, width: 2)
            .padding(20)
            .offset(
                x: currentPosition.width,
                y: currentPosition.height)
            .gesture(DragGesture()
                .onChanged { value in
                    currentPosition = CGSize(
                        width: value.translation.width + newPosition.width,
                        height: value.translation.height + newPosition.height)
                }
                .onEnded { value in
                    currentPosition = CGSize(
                        width: value.translation.width + newPosition.width,
                        height: value.translation.height + newPosition.height)
                    newPosition = currentPosition
                }
            )
        // --- Passaggio 2: Collega il TextField allo stato del focus ---
            .focused($isTextFieldFocused)
        
        // --- Passaggio 3: Aggiungi la Toolbar per la tastiera ---
            .toolbar {
                // Usiamo un ToolbarItemGroup con la placement specifica '.keyboard'
                ToolbarItemGroup(placement: .keyboard) {
                    // Bottone per il Font
                    Button {
                        print("Azione per cambiare Font...")
                    } label: {
                        Image(systemName: "textformat.characters")
                    }
                    
                    // Bottone per lo Stile
                    Button {
                        print("Azione per cambiare Stile...")
                    } label: {
                        Image(systemName: "bold")
                    }
                    
                    // Bottone per la Dimensione
                    Button {
                        print("Azione per cambiare Dimensione...")
                    } label: {
                        Image(systemName: "textformat.size")
                    }
                    
                    
                    Spacer()
                    Button {
                        isTextFieldFocused = false
                        if inputText.count > 0 {
                           
                            let screenCenter = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
                            
                            
                            let finalScreenPoint = CGPoint(x: screenCenter.x + newPosition.width,
                                                           y: screenCenter.y + newPosition.height)
                           
                            let activeLayerID = EditorModel.shared.activeCanvasId
                            if let canvasCenterPoint = EditorModel.shared.convertScreenPointToCanvasPoint(finalScreenPoint, for: activeLayerID) {
                                
                                // 4. Ora chiamiamo addTextStroke con la coordinata CORRETTA.
                                EditorModel.shared.addTextStroke(text: inputText, center: canvasCenterPoint)
                                
                            } else {
                                print("Errore: impossibile convertire le coordinate per la canvas attiva.")
                            }
                            
                            //EditorModel.shared.addTextStroke(text: inputText, position: newPosition)
                        }
                        EditorModel.shared.showTextInput = false
                    } label: {
                        Image(systemName: "return")
                    }
                    
                }
            }
        //      enumerateFonts()
        
    }
}
