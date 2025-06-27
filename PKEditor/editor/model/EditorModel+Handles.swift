//
//  EditorModel+Menu.swift
//  PKEditor
//
//  Created by Luca Rocchi on 22/06/25.
//

import Foundation
import Combine
import UIKit
@preconcurrency import PencilKit


extension EditorModel {
    // --- NUOVI METODI PER LA TRASFORMAZIONE LIVE ---

       /// Chiamato all'inizio di un gesto di trascinamento.
       func startLiveTransform() {
           // 1. Salva lo stato originale dello stroke per l'undo.
           originalStrokeForUndo = selectedStroke
           
           // 2. Inizia un gruppo di annullamento.
           //activeUndoManager?.beginUndoGrouping()
       }
       
       /// Chiamato alla fine di un gesto.
       func commitLiveTransform() {
           // 1. Assicurati che ci sia uno stato originale da ripristinare.
           /*guard let originalStroke = originalStrokeForUndo,
                 let currentStroke = selectedStroke,
                 let activeLayer = layers.first(where: { $0.id == activeCanvasId }),
                 //let undoManager = activeUndoManager else {
               //activeUndoManager?.endUndoGrouping() // Chiudi sempre il gruppo
               return
           }*/

           // 2. Registra l'operazione di undo.
           //    L'azione sarà rimettere lo stroke originale al suo posto.
           //undoManager.registerUndo(withTarget: self) { target in
    //    target.replaceStroke(originalStroke, inLayer: activeLayer)
    //     }
           
           // 3. Chiudi il gruppo, finalizzando l'operazione.
           //undoManager.endUndoGrouping()
           
           // Pulisci lo stato temporaneo.
           //originalStrokeForUndo = nil
       }
       
       /// Metodo helper per sostituire uno stroke, necessario per l'undo.
       func replaceStroke(_ strokeToInsert: PKStroke, in layer: LayerCanvasModel) {
           /*
           commitLiveTransform() // Questo ricorsivamente aggiungerà l'azione di redo
           
           // Poi eseguiamo la sostituzione.
           guard let layerIndex = layers.firstIndex(where: { $0.id == layer.id }),
                 var drawing = layers[layerIndex].drawing,
                 let oldStrokeIndex = drawing.strokes.firstIndex(where: { $0.randomSeed == strokeToInsert.randomSeed })
           else { return }
           
           drawing.strokes[oldStrokeIndex] = strokeToInsert
           layers[layerIndex].drawing = drawing
           self.selectedStroke = strokeToInsert
           
           Task { ... } // Aggiorna le maniglie come prima
            */
       }

       /// Applica una scala allo stroke (non registra l'undo).
       func applyLiveScale(scaleX: CGFloat, scaleY: CGFloat) {
           /*
           guard let selectedStroke = self.selectedStroke else { return }
           
           let bounds = originalStrokeForUndo?.renderBounds ?? selectedStroke.renderBounds
           let center = CGPoint(x: bounds.midX, y: bounds.midY)
           let scaleTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
           
           var finalTransform = CGAffineTransform.identity
           finalTransform = finalTransform.translatedBy(x: center.x, y: center.y)
           finalTransform = finalTransform.concatenating(scaleTransform)
           finalTransform = finalTransform.translatedBy(x: -center.x, y: -center.y)
           
           // Applica la trasformazione partendo sempre dallo stato originale
           selectedStroke.transform = (originalStrokeForUndo ?? selectedStroke).transform.concatenating(finalTransform)
           
           // Forza l'aggiornamento della UI
           objectWillChange.send()
            */
       }
   
}
