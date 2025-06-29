//
//  EditorModel+Canvas.swift
//  PKEditor
//
//  Created by Luca Rocchi on 22/06/25.
//


import Foundation
import Combine
import UIKit
@preconcurrency import PencilKit


extension EditorModel {
    
    func addTextStroke(text: String, center: CGPoint) {
        // 1. Trova l'indice del layer attivo.
        guard let layer = layers.first(where: { $0.id == activeCanvasId }) else {
            print("Errore: Nessun layer attivo trovato per aggiungere il testo.")
            return
        }
        //let layer = layers[layerIndex]
        // 2. Definisci i parametri per il tuo testo.
        //    In futuro potrai renderli personalizzabili dall'utente.
        //let font = UIFont.systemFont(ofSize: 80, weight: .bold)
        let font = currentFont
        //let font = UIFont(name: "Verdana", size: 19)!
        
        let color = textStampWrapper.toolItem.color
        let width: CGFloat = 3.0
        let scale: CGFloat = 1.0
        
        // 3. Convertiamo la posizione (che è un offset) in un punto centrale.
        //    NOTA: Questo assume che la posizione iniziale della TextInput sia (0,0)
        //    rispetto alla canvas. Potrebbe essere necessario un aggiustamento.
        //let center = CGPoint(x: position.width, y: position.height)
        //let center = CGPoint(x: 200, y: 130)
        
        // 4. Chiama il nostro convertitore per creare gli stroke.
        let newStrokes = FontStrokeConverter.createStrokes(
            fromText: text,
            font: font,
            at: center,
            color: color,
            width: width,
            scale: scale
        )
        
        guard !newStrokes.isEmpty else {
            print("Conversione del testo in stroke non ha prodotto risultati.")
            return
        }
        
        if let canvas = layer.canvas {
            let drawing1 = PKDrawing(strokes: newStrokes)
            let newDrawing1 = canvas.drawing.appending(drawing1)
            Task { @MainActor in
                //setNewDrawingUndoable(newDrawing1,to:canvas)
                //setNewDrawingUndoable(newDrawing1,to:layer)
                performAndRegisterDrawing(
                    newDrawing1,
                    on:layer,
                    actionName: "AddTextStroke"
                )
            }
        }
    }
    
    @MainActor
    private func updateDrawingAtomically(
        to newDrawing: PKDrawing,
        on layer: LayerCanvasModel
    ) -> PKDrawing {
        
        // 1. Leggi lo stato vecchio e attuale DAL MODELLO. Il modello è la verità.
        let oldDrawing = layer.drawing
        
        guard oldDrawing.dataRepresentation() != newDrawing.dataRepresentation() else {
                return oldDrawing
            }
            
        
        // 3. Imposta il flag per silenziare il delegate
        self.isApplyingProgrammaticChange = true
        
        // 4. SINCRONIZZA ATOMICAMENTE
        // Aggiorna prima il modello
        layer.drawing = newDrawing
        // Subito dopo, aggiorna la vista con lo stesso identico oggetto
        layer.canvas?.drawing = newDrawing
        
        // 5. Rilascia il flag
        self.isApplyingProgrammaticChange = false
        
        // 6. Restituisci lo stato precedente per l'UndoManager
        return oldDrawing
    }
    
    @MainActor
    func performAndRegisterDrawing(
        _ newDrawing: PKDrawing,
        on layer: LayerCanvasModel,
        actionName: String // Es. "Aggiungi Forma" o "Disegno"
    ) {
        // Prendi lo stato attuale DAL MODELLO
        //let oldDrawing = layer.drawing

        // Non fare nulla se non c'è un cambiamento reale
        //guard oldDrawing.strokes != newDrawing.strokes else { return }

        // Esegui il cambiamento usando il nostro setter privato
        let oldDrawing = self.updateDrawingAtomically(to: newDrawing, on: layer)
       
        // Registra l'azione di UNDO con l'UndoManager.
        // L'UndoManager gestirà il REDO automaticamente!
        layer.canvas?.undoManager?.registerUndo(withTarget: self) { target in
            // L'azione di UNDO è semplicemente eseguire di nuovo questa stessa funzione
            // con il disegno vecchio. L'UndoManager capirà che questa è un'operazione
            // di undo e la metterà nello stack di REDO.
            target.performAndRegisterDrawing(oldDrawing, on: layer, actionName: actionName)
        }

        // Imposta il nome dell'azione (visibile nel menu Modifica -> Annulla "Azione")
        // Lo facciamo solo se non stiamo già eseguendo un undo o un redo.
        if let undoManager = layer.canvas?.undoManager, !undoManager.isUndoing, !undoManager.isRedoing {
            undoManager.setActionName(actionName)
        }
    }
    

 
    func setBackgroundColor(){
        for layer in self.layers {
            if let canvas = layer.canvas {
                canvas.backgroundColor = .clear
                canvas.isOpaque = false
            }
        }
        if layers.count > 0 && backgroundColor != .clear{
            let layer = layers[0]
            if let canvas = layer.canvas {
                canvas.backgroundColor = backgroundColor
                canvas.isOpaque = backgroundColor != .clear
            }
            
        }
    }
    
    func convertScreenPointToCanvasPoint(_ screenPoint: CGPoint, for layerID: Int) -> CGPoint? {
        
        
        guard let layer = layers.first(where: { $0.id == layerID }) else {
            print("Errore: Nessun layer attivo trovato per aggiungere il testo.")
            return nil
        }
        
        // 1. Troviamo la canvas attiva dal nostro dizionario.
        guard let canvas = layer.canvas else {
            print("Errore di conversione: Canvas non trovata per il layer \(layerID)")
            return nil
        }
        
        // 2. Troviamo la finestra dell'app, che rappresenta il sistema di coordinate "globali".
        guard let window = canvas.window else {
            print("Errore di conversione: Finestra della canvas non trovata.")
            return nil
        }
        
        // 3. Usiamo il metodo 'convert' di UIView.
        //    Chiediamo alla nostra 'canvas' di convertire il 'screenPoint',
        //    dicendogli che il punto di partenza proviene dal sistema di coordinate della 'finestra'.
        let canvasPoint = canvas.convert(screenPoint, from: window)
        
        return canvasPoint
    }
    func rotateStroke(byDegrees degrees: Double){
        let rotation = CGFloat(degrees) * .pi / 180.0
        rotateStroke(rotation,state: UIRotationGestureRecognizer.State.ended)
    }
    
    func rotateStroke(_ rotation: CGFloat,state:UIRotationGestureRecognizer.State?){
       
        
        guard let layer = layers.first(where: { $0.id == activeCanvasId }) , let canvasView = layer.canvas else { return }
        guard let selectedStroke = selectedStroke else { return }
       
        //if state == .began {
        //    EditorModel.shared.isApplyingProgrammaticChange = true
        //}
        
        print("rotateStroke")
        guard let strokeIndex = canvasView.drawing.strokes.firstIndex(where: { $0.randomSeed == selectedStroke.randomSeed }) else { return }
        
        // 2. Calcoliamo la rotazione attorno al centro dello stroke.
        let bounds = selectedStroke.renderBounds
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: center.x, y: center.y)
        transform = transform.rotated(by: rotation)
        transform = transform.translatedBy(x: -center.x, y: -center.y)

        // 3. Applichiamo la trasformazione allo stroke.
        var modifiedStroke = selectedStroke
        modifiedStroke.transform = selectedStroke.transform.concatenating(transform)

        // 4. Creiamo un nuovo disegno SOSTITUENDO lo stroke.
        var newStrokes = canvasView.drawing.strokes
        newStrokes.remove(at: strokeIndex) // Rimuoviamo il vecchio
        newStrokes.insert(modifiedStroke, at: strokeIndex) // Inseriamo quello nuovo
        
        let newDrawing = PKDrawing(strokes: newStrokes)
        
        // 5. Usiamo il nostro metodo di undo/redo che è già robusto.
        //EditorModel.shared.setNewDrawingUndoable(newDrawing, to: canvasView)
        //EditorModel.shared.setNewDrawingUndoable(newDrawing, to: layer)
        
        //if state == .ended {
            performAndRegisterDrawing(
                newDrawing,
                on:layer,
                actionName: "rotateStroke"
            )
              
            // this must be @Published
            EditorModel.shared.selectedStroke =  canvasView.drawing.strokes[strokeIndex]
            //EditorModel.shared.isApplyingProgrammaticChange = false
         
            Task {
                if let canvas = layer.canvas, let coordinator = canvas.delegate as? LayerCanvasView.Coordinator {
                    coordinator.updateHandlesOverlay(for: canvas)
                }
            }
        /*}else if state == .changed {
            layer.canvas?.drawing = newDrawing
          
        }else{
            //EditorModel.shared.isApplyingProgrammaticChange = true
         
        }*/
        
        
    }
    
    
    func rotateDrawing(byDegrees degrees: Double) {
        
        guard let layer = layers.first(where: { $0.id == activeCanvasId }) else { return }
        var drawing = layer.canvas!.drawing
        
        // Questa volta prendiamo solo il riferimento all'ultimo stroke
        guard let lastStroke = drawing.strokes.last else {
            print("Nessuno stroke da ruotare.")
            return
        }
        
        let lastStrokeBounds = lastStroke.renderBounds
        let center = CGPoint(x: lastStrokeBounds.midX, y: lastStrokeBounds.midY)
        
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: center.x, y: center.y)
        transform = transform.rotated(by: CGFloat(degrees) * .pi / 180.0)
        transform = transform.translatedBy(x: -center.x, y: -center.y)
        
        drawing.transform(using:transform)
        
        if let canvas = layer.canvas {
            Task { @MainActor in
                //EditorModel.shared.setNewDrawingUndoable(drawing,to:canvas)
                //EditorModel.shared.setNewDrawingUndoable(drawing,to:layer)
                performAndRegisterDrawing(
                    drawing,
                    on:layer,
                    actionName: "rotateDrawing"
                )
            }
            
        }
        
        //layers[layerIndex].drawing = drawing
        
    }
    
    /// Directly sets the contentOffset on all other canvases.
    func propagateScrollOffset(_ offset: CGPoint, from sourceLayerID: Int) {
        // We iterate through our main source of truth: the layers array.
        for layer in layers {
            // We only update the canvases that are NOT the source of the scroll.
            if layer.id != sourceLayerID {
                // Access the canvas directly from the layer model.
                layer.canvas?.contentOffset = offset
            }
        }
    }
    
    /// Directly sets the zoomScale on all other canvases.
    func propagateZoomScale(_ scale: CGFloat, from sourceLayerID: Int) {
        for layer in layers {
            if layer.id != sourceLayerID {
                layer.canvas?.zoomScale = scale
            }
        }
    }
    
    func propagateTransform(_ transform: CGAffineTransform, from sourceLayerID: Int) {
        for layer in layers {
            if layer.id != sourceLayerID {
                // Applichiamo la stessa identica transform
                layer.canvas?.transform = transform
            }
        }
    }
    
    /// Scala lo stroke selezionato. Può essere uniforme o non uniforme.
    func scaleSelectedStroke(scaleX: CGFloat, scaleY: CGFloat) {
        guard var selectedStroke = self.selectedStroke else { return }
        
        // 2. Trova il layer e il disegno a cui appartiene
        
        guard let layer = layers.first(where: { $0.id == activeCanvasId }) else {
            print("Errore: Nessun layer attivo trovato per aggiungere il testo.")
            return
        }
        guard let strokeIndex = layer.drawing.strokes.firstIndex(where: { $0.randomSeed == selectedStroke.randomSeed }) else {
            print("Error: Could not find the selected stroke in the drawing's strokes array.")
            return
        }
        let bounds = selectedStroke.renderBounds
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        // Crea una trasformazione di scala non uniforme
        let scaleTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        
        // Applica la trasformazione attorno al centro dello stroke
        var finalTransform = CGAffineTransform.identity
        finalTransform = finalTransform.translatedBy(x: center.x, y: center.y)
        finalTransform = finalTransform.concatenating(scaleTransform)
        finalTransform = finalTransform.translatedBy(x: -center.x, y: -center.y)
        
        // Applica la nuova trasformazione
        selectedStroke.transform = selectedStroke.transform.concatenating(finalTransform)
        
        var newStrokes = layer.drawing.strokes
        newStrokes[strokeIndex] = selectedStroke
        
        // 6. Creiamo un PKDrawing completamente nuovo e lo riassegniamo.
        //    Questa riassegnazione è ciò che scatena l'aggiornamento della UI.
        let newDrawing = PKDrawing(strokes: newStrokes)
        //layer.drawing = newDrawing
        
        EditorModel.shared.performAndRegisterDrawing(
            newDrawing,
            on:layer,
            actionName: "scaleStroke"
        )
        
        EditorModel.shared.selectedStroke =    newStrokes[strokeIndex]
        
        // Aggiorna il riquadro di selezione
        Task {
            if let canvas = layer.canvas, let coordinator = canvas.delegate as? LayerCanvasView.Coordinator {
                coordinator.updateHandlesOverlay(for: canvas)
            }
        }
    }
    
    
    func shearSelectedStroke(by dragOffset: CGSize, handleAnchor: HandleAnchor) {
        // 1. Assicurati che ci sia uno stroke selezionato
        guard var selectedStroke = self.selectedStroke else { return }
        
        // 2. Trova il layer e il disegno a cui appartiene
        
        guard let layer = layers.first(where: { $0.id == activeCanvasId }) else {
            print("Errore: Nessun layer attivo trovato per aggiungere il testo.")
            return
        }
        
        
        let bounds = selectedStroke.renderBounds
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        // 3. Calcola il fattore di shearing in base alla maniglia trascinata
        var shearFactorX: CGFloat = 0
        var shearFactorY: CGFloat = 0
        
        switch handleAnchor {
        case .top: // Inclina orizzontalmente
            shearFactorX = dragOffset.width / bounds.height
        case .bottom:
            shearFactorX = dragOffset.width / bounds.height
        case .left: // Inclina verticalmente
            shearFactorY = dragOffset.height / bounds.width
        case .right:
            shearFactorY = dragOffset.height / bounds.width
        default:
            // Per ora non gestiamo gli angoli o il centro per lo shearing
            return
        }
        
        // 4. Crea la trasformazione di shearing
        let shearTransform = CGAffineTransform(a: 1, b: shearFactorY, c: shearFactorX, d: 1, tx: 0, ty: 0)
        
        // 5. Applica la trasformazione attorno al centro dello stroke per un effetto naturale
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        var finalTransform = CGAffineTransform.identity
        finalTransform = finalTransform.translatedBy(x: center.x, y: center.y)
        finalTransform = finalTransform.concatenating(shearTransform)
        finalTransform = finalTransform.translatedBy(x: -center.x, y: -center.y)
        
        // 6. Applica la trasformazione allo stroke
        selectedStroke.transform = selectedStroke.transform.concatenating(finalTransform)
        
        // 7. Notifica alla UI che il layer è cambiato per forzare l'aggiornamento
        layer.objectWillChange.send()
        
        // Aggiorna il riquadro di selezione
        if let canvas = layer.canvas {
            // Dobbiamo forzare l'aggiornamento del riquadro di selezione
            // lo facciamo tramite un task asincrono per assicurarci che la trasformazione
            // sia stata renderizzata prima di ricalcolare i bounds
            Task {
                if let coordinator = (canvas.delegate as? LayerCanvasView.Coordinator) {
                    coordinator.updateHandlesOverlay(for: layer.canvas!)
                }
            }
        }
    }
}
