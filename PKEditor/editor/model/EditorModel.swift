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
    let defProjectName: String = "drawingProject"
    
    @Published var layers: [LayerCanvasModel] = []
    @Published var shapeStampWrapper = ShapeStampWrapper()
    @Published var textStampWrapper = TextStampWrapper()
    @Published var projectID = UUID()
    @Published var projectName: String = ""
    
    @Published var showAccessorySheet: Bool = false
    @Published var showPhotoPicker = false
    @Published var showDocPicker = false
    @Published var showTextInput = false
    @Published var saveProjectAs: Bool = false
    @Published var showLayerEditorDetail: Bool = false
    @Published var showFontPicker:Bool = false
    @Published var showFontSheet = false
    @Published var activeCanvasId: Int = 1
    @Published var contentSize: CGSize = CGSize(width: 1000, height: 1000)
    @Published var currentFont: UIFont = UIFont.systemFont(ofSize: 64, weight: .regular){
        didSet {
            saveFontToUserDefaults()
        }
    }
    @Published var backgroundColor = UIColor.clear {
        didSet {
            setBackgroundColor()
        }
    }
    
    var contentOffset: CGPoint = .zero
    var zoomScale: CGFloat = 1.0
    let minimumZoomScale = 0.33333
    let maximumZoomScale = 3.0
    //let minimumZoomScale = 1.0
    //let maximumZoomScale = 1.0
 
    private let fontNameKey = "EditorCurrentFontName"
    private let fontSizeKey = "EditorCurrentFontSize"
  
    var recentProjects:[String] = []
    
    var toolPicker: PKToolPicker?
    var mainMenu:UIMenu!
    var onPublish: ((_ image:UIImage) -> Void)? = nil
  
    //@Published
    var selectedStroke: PKStroke? = nil
    var locationInDrawing : CGPoint = .zero
    
    override init() {
        super.init()
        projectName = defProjectName
        loadFontFromUserDefaults()
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
    
    
    func zoomToFit() {
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
    
    func saveFontToUserDefaults() {
        let fontToSave = self.currentFont
        
        // Otteniamo e salviamo le due proprietà semplici
        let fontName = fontToSave.fontName
        let fontSize = fontToSave.pointSize
        
        let defaults = UserDefaults.standard
        defaults.set(fontName, forKey: fontNameKey)
        defaults.set(fontSize, forKey: fontSizeKey)
        
        print("✅ Font salvato: \(fontName) @ \(fontSize)pt")
    }
    
    // --- NUOVA FUNZIONE PER CARICARE IL FONT ---
    
    /// Carica il nome e la dimensione del font da UserDefaults e aggiorna la proprietà 'currentFont'.
    func loadFontFromUserDefaults() {
        let defaults = UserDefaults.standard
        
        // Leggiamo il nome, usando un font di sistema come valore di default se non c'è nulla
        let savedName = defaults.string(forKey: fontNameKey) ?? UIFont.systemFont(ofSize: 48).fontName
        
        // Leggiamo la dimensione. Se la chiave non esiste, .double(forKey:) restituisce 0.
        // Quindi controlliamo prima se esiste, altrimenti usiamo un default.
        var savedSize: CGFloat
        if defaults.object(forKey: fontSizeKey) != nil {
            savedSize = defaults.double(forKey: fontSizeKey)
        } else {
            savedSize = 48.0
        }
        
        // Ricreiamo l'oggetto UIFont.
        // L'inizializzatore UIFont(name:size:) può fallire se il font non è più presente
        // sul sistema, quindi forniamo un fallback per sicurezza.
        self.currentFont = UIFont(name: savedName, size: savedSize) ?? .systemFont(ofSize: savedSize)
        
        print("✅ Font caricato: \(self.currentFont.fontName) @ \(self.currentFont.pointSize)pt")
    }
    
}

