//
//  HandleAnchor.swift
//  PKEditor
//
//  Created by Luca Rocchi on 25/06/25.
//


import SwiftUI

/// Un punto di ancoraggio per le maniglie di controllo.
enum HandleAnchor {
    case topLeft, top, topRight
    case left, center, right
    case bottomLeft, bottom, bottomRight
}

struct EditingHandlesView: View {
    // La dimensione e posizione del rettangolo da disegnare
    let frame: CGRect
    
    // Dimensione delle maniglie
    private let handleSize: CGFloat = 20
    var editor = EditorModel.shared
    
    @State private var initialFrameOnDrag: CGRect?
    @State private var isDragging = false

    private let hapticGenerator = UIImpactFeedbackGenerator(style: .heavy)

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 1. Disegniamo il rettangolo di contorno
            Rectangle()
                .stroke(Color.blue, lineWidth: 1.5)
            
            // 2. Disegniamo le 9 maniglie di controllo
            
            // Angoli
            //handleView(for: .topLeft)
            //handleView(for: .topRight)
            //handleView(for: .bottomLeft)
            //handleView(for: .bottomRight)
            
            // Lati
            /*
            handleView(for: .top)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // Potremmo mostrare un'anteprima qui in futuro
                        }
                        .onEnded { value in
                            // Quando il gesto finisce, chiamiamo la nostra nuova funzione
                            editor.shearSelectedStroke(by: value.translation, handleAnchor: .top)
                        }
                )
             */
            handleView(for: .bottom)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                                   if !isDragging {
                                       isDragging = true
                                       hapticGenerator.impactOccurred()
                                   }
                                   
                                  
                                   let initialHeight = frame.height
                                   if initialHeight > 0 {
                                       let newHeight = initialHeight + value.translation.height
                                       let scaleFactor = newHeight / initialHeight
                                       if scaleFactor > 0.1 {
                                           // Chiama il metodo di preview, non quello di commit
                                           //editor.applyLiveScale(scaleX: scaleFactor, scaleY: scaleFactor)
                                       }
                                   }
                               }
                        .onEnded { value in
                            // Il gesto è terminato, applichiamo lo stretch
                            isDragging = false
                           let initialHeight = frame.height
                           // Se trasciniamo a destra, solo la larghezza cambia
                           let newHeight = initialHeight + value.translation.height
                           
                           // Calcoliamo il fattore di scala solo per l'asse X
                           let scaleY = newHeight / initialHeight
                           let scaleX: CGFloat = 1.0
                           
                           guard scaleY > 0.1 else { return }
                           
                           editor.scaleSelectedStroke(scaleX: scaleX, scaleY: scaleY)
                            // Quando il gesto finisce, chiamiamo la nostra nuova funzione
                            //editor.shearSelectedStroke(by: value.translation, handleAnchor: .right)
                        }
                )
            /*
            handleView(for: .left)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // Potremmo mostrare un'anteprima qui in futuro
                        }
                        .onEnded { value in
                            // Quando il gesto finisce, chiamiamo la nostra nuova funzione
                            editor.shearSelectedStroke(by: value.translation, handleAnchor: .left)
                        }
                )
             */
            handleView(for: .right)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                                   if !isDragging {
                                       isDragging = true
                                       hapticGenerator.impactOccurred()
                                   }
                                   
                                  
                                   let initialWidth = frame.width
                                   if initialWidth > 0 {
                                       let newWidth = initialWidth + value.translation.width
                                       let scaleFactor = newWidth / initialWidth
                                       if scaleFactor > 0.1 {
                                           // Chiama il metodo di preview, non quello di commit
                                           //editor.applyLiveScale(scaleX: scaleFactor, scaleY: scaleFactor)
                                       }
                                   }
                               }
                        .onEnded { value in
                            // Il gesto è terminato, applichiamo lo stretch
                            isDragging = false
                           let initialWidth = frame.width
                           // Se trasciniamo a destra, solo la larghezza cambia
                           let newWidth = initialWidth + value.translation.width
                           
                           // Calcoliamo il fattore di scala solo per l'asse X
                           let scaleX = newWidth / initialWidth
                           let scaleY: CGFloat = 1.0 // La scala Y rimane invariata
                           
                           guard scaleX > 0.1 else { return }
                           
                           editor.scaleSelectedStroke(scaleX: scaleX, scaleY: scaleY)
                            // Quando il gesto finisce, chiamiamo la nostra nuova funzione
                            //editor.shearSelectedStroke(by: value.translation, handleAnchor: .right)
                        }
                )
            
            // Centro (spesso usato per la rotazione)
            //handleView(for: .center)
        }
        // Posizioniamo l'intera vista usando il frame che ci viene passato
        //.frame(width: frame.width, height: frame.height)
        //.position(x: frame.midX, y: frame.midY)
    }
    
    /// Una funzione helper per creare una singola maniglia e posizionarla.
    @ViewBuilder
    private func handleView(for anchor: HandleAnchor) -> some View {
        Circle()
            .fill(Color.blue)
            .frame(width: handleSize, height: handleSize)
            .padding(10)
            .contentShape(Circle())
            //.overlay(Circle().stroke(Color.blue, lineWidth: 1.0))
        // Posiziona la maniglia all'interno del frame
            .position(position(for: anchor))
        // In futuro, aggiungeremo un .gesture() qui per renderla trascinabile
    }
    
    /// Calcola la coordinata per una specifica maniglia.
    private func position(for anchor: HandleAnchor) -> CGPoint {
        switch anchor {
        case .topLeft:      return CGPoint(x: 0, y: 0)
        case .top:          return CGPoint(x: frame.width / 2, y: 0)
        case .topRight:     return CGPoint(x: frame.width, y: 0)
        case .left:         return CGPoint(x: 0, y: frame.height / 2)
        case .center:       return CGPoint(x: frame.width / 2, y: frame.height / 2)
        case .right:        return CGPoint(x: frame.width, y: frame.height / 2)
        case .bottomLeft:   return CGPoint(x: 0, y: frame.height)
        case .bottom:       return CGPoint(x: frame.width / 2, y: frame.height)
        case .bottomRight:  return CGPoint(x: frame.width, y: frame.height)
        }
    }
}
