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
    private let handleSize: CGFloat = 12

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 1. Disegniamo il rettangolo di contorno
            Rectangle()
                .stroke(Color.blue, lineWidth: 1.5)
            
            // 2. Disegniamo le 9 maniglie di controllo
            
            // Angoli
            handleView(for: .topLeft)
            handleView(for: .topRight)
            handleView(for: .bottomLeft)
            handleView(for: .bottomRight)
            
            // Lati
            handleView(for: .top)
            handleView(for: .bottom)
            handleView(for: .left)
            handleView(for: .right)
            
            // Centro (spesso usato per la rotazione)
            handleView(for: .center)
        }
        // Posizioniamo l'intera vista usando il frame che ci viene passato
        //.frame(width: frame.width, height: frame.height)
        //.position(x: frame.midX, y: frame.midY)
    }
    
    /// Una funzione helper per creare una singola maniglia e posizionarla.
    @ViewBuilder
    private func handleView(for anchor: HandleAnchor) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: handleSize, height: handleSize)
            .overlay(Circle().stroke(Color.blue, lineWidth: 1.5))
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

// Per vedere un'anteprima in Xcode
#Preview {
    ZStack {
        // Simula uno sfondo per vedere meglio la vista
        Color.gray.opacity(0.3)
        
        // Esempio di come usare la vista
        EditingHandlesView(frame: CGRect(x: 100, y: 150, width: 200, height: 150))
    }
}
