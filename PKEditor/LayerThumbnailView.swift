//
//  LayerThumbnailView.swift
//  PKEditor
//
//  Created by Luca Rocchi on 15/06/25.
//


import SwiftUI
import PencilKit

struct LayerThumbnailView: View {
    let drawing: PKDrawing
    let size: CGSize

    var body: some View {
        // Creiamo un'immagine dal nostro disegno
        if drawing.bounds.isEmpty {
                  // Se il disegno è vuoto, mostriamo un rettangolo trasparente
                  // per mantenere le dimensioni corrette nel layout.
                  Rectangle().fill(Color.clear)
              } else {
                  // --- LOGICA CORRETTA ---
                  // 1. Usiamo drawing.bounds per definire l'area da "fotografare".
                  //    Questo garantisce di inquadrare sempre l'intero disegno.
                  // 2. Usiamo UIScreen.main.scale per una qualità dell'immagine ottimale
                  //    in base alla densità di pixel dello schermo (Retina, etc.).
                  Image(uiImage: drawing.image(from: drawing.bounds, scale: UIScreen.main.scale))
                      .resizable()
                      .scaledToFit()
                      .id(drawing.strokes.count)
              }
    }
}
