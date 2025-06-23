//
//  EditorModel.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//

import Foundation
import Combine
import UIKit
@preconcurrency import PencilKit

/*struct ProjectData: Codable {
 let contentSize: CGSize
 let contentOffset: CGPoint
 let layers: [LayerCanvasModel]
 }*/


@MainActor
class EditorModel: NSObject,ObservableObject {
    static let shared = EditorModel()
    @Published var layers: [LayerCanvasModel] = []
    @Published var shapeStampWrapper = ShapeStampWrapper()
    @Published var textStampWrapper = TextStampWrapper()
    @Published var projectID = UUID()
    
    private var cancellables = Set<AnyCancellable>()
    @Published var defProjectName: String = "drawingProject"
    @Published var projectName: String = ""
    
    @Published var isShowingAccessorySheet: Bool = false
    @Published var showPhotoPicker = false
    @Published var showDocPicker = false
    @Published var showTextInput = false
    @Published var saveProjectAs: Bool = false
    @Published var showLayerEditorDetail: Bool = false
    
    @Published var activeCanvasId: Int = 1
    
    @Published var contentOffset: CGPoint = .zero
    //@Published var contentSize: CGSize = .zero
    @Published var contentSize: CGSize = CGSize(width: 1000, height: 1000)
    @Published var minimumZoomScale = 0.3
    @Published var maximumZoomScale = 5.0
    @Published var zoomScale: CGFloat = 1.0

    //var canvasViews: [Int: PKCanvasView?] = [:]
    var recentProjects:[String] = []
    
    var toolPicker: PKToolPicker?
    var mainMenu:UIMenu!
    
    override init() {
        super.init()
        projectName = defProjectName
        addLayer()
        activeCanvasId = 1
        self.recentProjects = getRecentProjects()
        if self.recentProjects.count > 0 {
            let name = self.recentProjects[0]
            loadProject(name)
        }
    }
    
    func addLayer() {
        let canvasId = layers.count + 1
        let layer = LayerCanvasModel(currentCanvasId: canvasId)
        layers.append(layer)
        activeCanvasId = canvasId
    }
    
    func rotateLastStroke(for layerID: Int, byDegrees degrees: Double) {
        
        guard let layerIndex = layers.firstIndex(where: { $0.id == layerID }) else { return }
        var drawing = layers[layerIndex].drawing
        
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
        layers[layerIndex].drawing = drawing
        
    }
    
    
    func zoomToFit() {
        // La logica per trovare i layer visibili e la canvas attiva rimane invariata
        let visibleLayers = self.layers.filter { $0.visible && !$0.drawing.bounds.isEmpty }
        guard !visibleLayers.isEmpty else { return }
        
        let totalBounds = visibleLayers.reduce(CGRect.null) { $0.union($1.drawing.bounds)
        }
        //let totalBounds = CGRect(x: 0,y: 0,width: contentSize.width,height: contentSize.height)
        
        
        guard let layer = layers.first(where: { $0.id == activeCanvasId }) else {
            print("Errore: Nessun layer attivo trovato per aggiungere il testo.")
            return
        }
        
        //let layer = layers[layerIndex]
        guard let activeCanvas = layer.canvas, // Usa il dizionario corretto
              !totalBounds.isNull, totalBounds.width > 0, totalBounds.height > 0 else {
            print("Impossibile calcolare lo zoom.")
            return
        }
        
        // --- LOGICA DI ZOOM (invariata) ---
        let canvasFrame = activeCanvas.bounds // Usiamo .bounds per la dimensione visibile effettiva
        let widthScale = canvasFrame.width / totalBounds.width
        let heightScale = canvasFrame.height / totalBounds.height
        let fitScale = min(widthScale, heightScale) * 0.95 // Aggiungiamo un piccolo margine del 5%
        
        // --- LOGICA DI CENTRATURA (NUOVA) ---
        
        // 1. Calcoliamo le dimensioni del nostro contenuto DOPO che è stato scalato
        let scaledContentWidth = totalBounds.width * fitScale
        let scaledContentHeight = totalBounds.height * fitScale
        
        // 2. Calcoliamo di quanto dobbiamo spostare l'origine per centrare il contenuto.
        //    Lo spazio vuoto orizzontale è (larghezza della vista - larghezza del contenuto scalato).
        //    L'offset sarà metà di quello spazio, ma non può essere negativo.
        var offsetX = (canvasFrame.width - scaledContentWidth) / 2.0
        var offsetY = (canvasFrame.height - scaledContentHeight) / 2.0
        
        // Se il contenuto scalato è più grande della vista, l'offset deve essere 0.
        offsetX = max(0, offsetX)
        offsetY = max(0, offsetY)
        
        // 3. L'offset finale deve tener conto anche della posizione originale del disegno.
        //    Sottraiamo l'origine del totalBounds (scalata) e aggiungiamo il nostro margine calcolato.
        
        let newContentOffset = CGPoint(
            x: totalBounds.origin.x * fitScale - offsetX,
            y: totalBounds.origin.y * fitScale - offsetY
        )
        print ("newContentOffset \(newContentOffset)")
        // --- APPLICAZIONE A TUTTE LE TELE ---
        
        // 4. Applichiamo sia lo zoom CHE il nuovo contentOffset a TUTTE le canvas.
        
        contentOffset = newContentOffset
        //contentOffset = .zero
        for layer in layers {
            let canvas = layer.canvas!
            canvas.minimumZoomScale = fitScale
            canvas.setZoomScale(fitScale, animated: false) // Prima imposta lo zoom senza animazione
            canvas.setContentOffset(contentOffset, animated: false) // Poi centra con una lieve animazione
        }
        
        print("Eseguito Zoom to Fit con centratura.")
    }
    
    func zoomTo1of1() {
        zoomScale = 1
        contentOffset = .zero
        for layer in layers {
            let canvas = layer.canvas!
            canvas.setZoomScale(zoomScale, animated: false) // Prima imposta lo zoom senza animazione
            canvas.setContentOffset(contentOffset, animated: false) // Poi centra con una lieve animazione
        }
    }
    /*
    /// Registra una PKCanvasView nel modello quando viene creata.
    func registerCanvasView(_ canvasView: PKCanvasView, forLayerID layerID: Int) {
        canvasViews[layerID] = canvasView
    }
    
    /// Rimuove il riferimento a una PKCanvasView quando viene distrutta.
    func unregisterCanvasView(forLayerID layerID: Int) {
        canvasViews[layerID] = nil
    }
    */
    
}

