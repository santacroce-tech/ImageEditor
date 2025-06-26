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
                setNewDrawingUndoable(newDrawing1,to:canvas)
            }
        }
    }
    
    
    @MainActor
    func setNewDrawingUndoable(_ newDrawing: PKDrawing, to canvasView: PKCanvasView) {
        let oldDrawing = canvasView.drawing
        guard oldDrawing.bounds != newDrawing.bounds || oldDrawing.strokes.count != newDrawing.strokes.count else {
            return
        }

        canvasView.drawing = newDrawing
        
        canvasView.undoManager?.registerUndo(withTarget: self) { target in
            Task{ @MainActor in
                target.setNewDrawingUndoable(oldDrawing, to: canvasView)
            }
        }
        // canvasView.undoManager?.setActionName("Add Shape")
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
                EditorModel.shared.setNewDrawingUndoable(drawing,to:canvas)
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
        
}
