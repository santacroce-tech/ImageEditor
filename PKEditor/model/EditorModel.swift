//
//  EditorModel.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//

import Foundation
import Combine
import UIKit
import PencilKit

struct ProjectData: Codable {
    let contentSize: CGSize
    let contentOffset: CGPoint
    let layers: [LayerCanvasModel]
}


@MainActor
class EditorModel: NSObject,ObservableObject {
    static let shared = EditorModel()
    @Published var layers: [LayerCanvasModel] = [] // Rimuovi LayerListModel
    @Published var animalStampWrapper = AnimalStampWrapper()
    @Published var projectID = UUID()
    
    private var cancellables = Set<AnyCancellable>()
    @Published var defProjectName: String = "drawingProject"
    @Published var projectName: String = ""
    
    @Published var isShowingAccessorySheet: Bool = false
    @Published var showPhotoPicker = false
    @Published var showDocPicker = false
    
    @Published var saveProjectAs: Bool = false
    @Published var showLayerEditorDetail: Bool = false
    
    @Published var activeCanvasId: Int = 1
    
    @Published var contentOffset: CGPoint = .zero
    //@Published var contentSize: CGSize = .zero
    @Published var contentSize: CGSize = CGSize(width: 1000, height: 1000)
    
    private var canvasViews: [Int: PKCanvasView?] = [:]
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
    /*
     func rotateLastStroke(for layerID: Int, byDegrees degrees: Double) {
     
     guard let layerIndex = layers.firstIndex(where: { $0.id == layerID }) else { return }
     var drawing = layers[layerIndex].drawing
     
     guard let lastStrokeIndex = drawing.strokes.indices.last else {
     print("Nessuno stroke da ruotare.")
     return
     }
     
     let lastStrokeBounds = drawing.strokes[lastStrokeIndex].renderBounds
     let center = CGPoint(x: lastStrokeBounds.midX, y: lastStrokeBounds.midY)
     
     // --- SEZIONE CORRETTA PER LA TRASFORMAZIONE ---
     
     // 1. Inizia con una trasformazione "identità" (cioè nessuna trasformazione).
     var transform = CGAffineTransform.identity
     
     // 2. Applica una traslazione per portare il centro all'origine (0,0).
     transform = transform.translatedBy(x: center.x, y: center.y)
     
     // 3. Applica la rotazione.
     let radians = CGFloat(degrees) * .pi / 180.0
     transform = transform.rotated(by: radians)
     
     // 4. Applica la traslazione inversa per riportare il centro alla sua posizione originale.
     transform = transform.translatedBy(x: -center.x, y: -center.y)
     
     // ----------------------------------------------
     
     // Applica la trasformazione finale all'ultimo stroke
     //drawing.strokes[lastStrokeIndex].transform(using: transform)
     DispatchQueue.main.async {
     drawing.strokes[lastStrokeIndex].transform = transform
     
     self.objectWillChange.send()
     self.layers[layerIndex].drawing = drawing
     }
     
     }
     */
    
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func checkIfProjectExists(name:String) -> Bool {
        let filename = "\(name).json"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        let filePath = url.path
        let fileManager = FileManager.default
        let exists = fileManager.fileExists(atPath: filePath)
        return exists
    }
    
    func saveProject(name:String? = nil) {
        let newName = name ?? projectName
        
        let filename = "\(newName).json"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        
        let thumbFilename = "\(newName).png"
        let thumbUrl = getDocumentsDirectory().appendingPathComponent(thumbFilename)
        
        let projectData = ProjectData(contentSize: self.contentSize, contentOffset: self.contentOffset,layers: self.layers)
        
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(projectData)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            print("✅ Progetto salvato con successo in: \(url.path)")
            projectName = newName
            
            
            if let image = renderLayers() , let pngData =  image.pngData() {
                // Ora puoi salvare questo 'pngData' su file
                
                try pngData.write(to: thumbUrl, options: [
                    .atomic, // Scrive su un file temporaneo e lo rinomina solo a operazione completata, per evitare corruzione.
                    //.completeFileProtection // Cripta il file quando il dispositivo è bloccato.
                ])
            }
            
        } catch {
            print("❌ Errore durante il salvataggio del progetto: \(error.localizedDescription)")
        }
        
        if name != nil {
            self.recentProjects = getRecentProjects()
            createPopupMenu()
        }
    }
    
    func newProject(){
        canvasViews.removeAll()
        layers.removeAll()
        projectName = defProjectName
        addLayer()
        activeCanvasId = 1
        self.projectID = UUID()
        
    }
    
    /// Carica un progetto da un file JSON e sostituisce i layer correnti.
    func loadProject(_ name: String = "drawingProject") {
        let filename = "\(name).json"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        loadProject(from: url)
        
    }
    
    func loadProject(from url: URL) {
        //let filename = "\(name).json"
        //let url = getDocumentsDirectory().appendingPathComponent(filename)
        let name = url.deletingPathExtension().lastPathComponent
        canvasViews.removeAll()
      
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: url)
            
            let loadedProject = try decoder.decode(ProjectData.self, from: data)
            self.contentSize = loadedProject.contentSize
            self.contentOffset = loadedProject.contentOffset
            self.layers = loadedProject.layers
           
            //let loadedLayers = try decoder.decode([LayerCanvasModel].self, from: data)
            //self.layers = loadedLayers
            activeCanvasId = 1
            projectName = name
            self.projectID = UUID()
            
            
            
            print("✅ Progetto caricato con successo.")
        } catch {
            print("❌ Errore durante il caricamento del progetto: \(error.localizedDescription)")
        }
    }
    
    func exportToGallery()  {
        // 4. Salva l'immagine finale nella galleria fotografica
        if let compositeImage = renderLayers() {
            UIImageWriteToSavedPhotosAlbum(compositeImage, self, #selector(imageSaveCompletion), nil)
            EditorModel.shared.showPhotoPicker = true
        }
    }
    
    
    func renderLayers() -> UIImage? {
         
         // 1. Filtra per ottenere solo i layer visibili e con qualcosa disegnato
         let visibleLayers = self.layers.filter { $0.visible && !$0.drawing.bounds.isEmpty }
         
         guard !visibleLayers.isEmpty else {
             print("Nessun layer visibile con contenuto da esportare.")
             return nil
         }
         
         // 2. Calcola il rettangolo totale che contiene tutti i disegni
         let totalBounds = visibleLayers.reduce(CGRect.null) { (result, layer) -> CGRect in
             return result.union(layer.drawing.bounds)
         }
         
         guard !totalBounds.isNull, totalBounds.width > 0, totalBounds.height > 0 else {
             print("Dimensioni del disegno non valide.")
             return nil
         }
         
         // 3. Usa UIGraphicsImageRenderer per creare l'immagine composita
         let renderer = UIGraphicsImageRenderer(bounds: totalBounds)
         
         let compositeImage = renderer.image { context in
             // Disegniamo i layer uno sopra l'altro, dal basso verso l'alto
             for layer in self.layers {
                 // Se il layer non è visibile, lo saltiamo
                 guard layer.visible else { continue }
                 
                 // Generiamo l'immagine per questo singolo layer
                 let layerImage = layer.drawing.image(from: totalBounds, scale: UIScreen.main.scale)
                 
                 // Disegniamo l'immagine nel contesto, rispettando la sua opacità
                 layerImage.draw(in: totalBounds, blendMode: .normal, alpha: layer.opacity)
             }
         }
         return compositeImage
       
     }

     /// Questo metodo rimane invariato. Viene chiamato al termine del salvataggio.
     @objc func imageSaveCompletion(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
         if let error = error {
             print("❌ Errore nel salvataggio dell'immagine composita: \(error.localizedDescription)")
         } else {
             print("✅ Immagine composita salvata con successo nella galleria!")
         }
     }
    
    func zoomToFit() {
        // La logica per trovare i layer visibili e la canvas attiva rimane invariata
        let visibleLayers = self.layers.filter { $0.visible && !$0.drawing.bounds.isEmpty }
        guard !visibleLayers.isEmpty else { return }

        let totalBounds = visibleLayers.reduce(CGRect.null) { $0.union($1.drawing.bounds) }
        
        guard let activeCanvas = canvasViews[activeCanvasId], // Usa il dizionario corretto
              !totalBounds.isNull, totalBounds.width > 0, totalBounds.height > 0 else {
            print("Impossibile calcolare lo zoom.")
            return
        }

        // --- LOGICA DI ZOOM (invariata) ---
        let canvasFrame = activeCanvas!.bounds // Usiamo .bounds per la dimensione visibile effettiva
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
            x: -totalBounds.origin.x * fitScale + offsetX,
            y: +totalBounds.origin.y * fitScale + offsetY
        )
        
        // --- APPLICAZIONE A TUTTE LE TELE ---
        
        // 4. Applichiamo sia lo zoom CHE il nuovo contentOffset a TUTTE le canvas.
        for id in canvasViews.keys {
            let canvas = canvasViews[id]!!
            canvas.minimumZoomScale = fitScale
            canvas.setZoomScale(fitScale, animated: false) // Prima imposta lo zoom senza animazione
            canvas.setContentOffset(newContentOffset, animated: false) // Poi centra con una lieve animazione
        }
        
        print("Eseguito Zoom to Fit con centratura.")
    }
     /*
      func zoomToFit() { // Non abbiamo più bisogno dell'ID del layer
        
        // 1. Filtra per ottenere solo i layer visibili e con qualcosa disegnato
        let visibleLayers = self.layers.filter { $0.visible && !$0.drawing.bounds.isEmpty }
        
        guard !visibleLayers.isEmpty else {
            print("Nessun layer visibile con contenuto per eseguire lo zoom.")
            return
        }
        
        // 2. Calcola il rettangolo totale che contiene TUTTI i disegni visibili
        let totalBounds = visibleLayers.reduce(CGRect.null) { (result, layer) -> CGRect in
            return result.union(layer.drawing.bounds)
        }

        // 3. Prendiamo la canvas attiva come riferimento per le dimensioni dello schermo
        guard let activeCanvas = canvasViews[activeCanvasId] as? PKCanvasView, // Assumendo che tu abbia una proprietà activeCanvasId nel modello
              !totalBounds.isNull, totalBounds.width > 0, totalBounds.height > 0 else {
            print("Impossibile calcolare lo zoom: canvas attiva non trovata o dimensioni non valide.")
            return
        }

        // 4. Calcoliamo lo zoom necessario per far stare il "totalBounds" nella vista.
        let canvasFrame = activeCanvas.frame
        let widthScale = canvasFrame.width / totalBounds.width
        let heightScale = canvasFrame.height / totalBounds.height
        let fitScale = min(widthScale, heightScale) * 0.95 // Aggiungiamo un piccolo margine del 5%
        
        // 5. Applichiamo il nuovo zoom a TUTTE le canvas registrate
        for canvas in canvasViews.values {
            guard let canvas = canvas else { continue }
            canvas.minimumZoomScale = fitScale
            canvas.setZoomScale(fitScale, animated: true)
        }
        
        print("Eseguito Zoom to Fit su tutti i layer con scala: \(fitScale)")
    }
      */
        
       /// Registra una PKCanvasView nel modello quando viene creata.
       func registerCanvasView(_ canvasView: PKCanvasView, forLayerID layerID: Int) {
           canvasViews[layerID] = canvasView
       }
       
       /// Rimuove il riferimento a una PKCanvasView quando viene distrutta.
       func unregisterCanvasView(forLayerID layerID: Int) {
           canvasViews[layerID] = nil
       }
    
    /*func loadRecent(){
        self.recentProjects.removeAll()
        self.recentProjects = getRecentProjects()
    }
     */
    
    private func getRecentProjects() -> [String] {
        self.recentProjects.removeAll()
     
        // Otteniamo il percorso della nostra cartella Documents
        guard let documentsURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            print("❌ Impossibile accedere alla cartella Documents.")
            return []
        }
        
        do {
            // 1. Otteniamo gli URL di tutti i file nella cartella
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.contentModificationDateKey], options: [])
            
            // 2. Filtriamo per tenere solo i file .json e otteniamo la loro data di modifica
            let jsonFiles = try fileURLs.compactMap { url -> (url: URL, modDate: Date)? in
                // Filtra per estensione .json
                guard url.pathExtension == "json" else {
                    return nil
                }
                // Ottieni le proprietà del file, inclusa la data di modifica
                let resources = try url.resourceValues(forKeys: [.contentModificationDateKey])
                guard let modificationDate = resources.contentModificationDate else {
                    return nil
                }
                return (url: url, modDate: modificationDate)
            }
            
            // 3. Ordiniamo l'array per data, dalla più recente alla più vecchia
            let sortedFiles = jsonFiles.sorted { $0.modDate > $1.modDate }
            
            // 4. Estraiamo solo i nomi dei file, rimuovendo l'estensione .json
            var projectNames = sortedFiles.map { $0.url.deletingPathExtension().lastPathComponent }
            
            print("✅ Trovati progetti recenti: \(projectNames)")
            projectNames = Array(projectNames.prefix(5))
            return projectNames
            
        } catch {
            print("❌ Errore durante la lettura dei file: \(error.localizedDescription)")
            return []
        }
    }
}


extension EditorModel {
     func createPopupMenu(){
        // --- Sottomenu "File" ---
        let saveAction = UIAction(title: "Save", image: nil) { _ in
            EditorModel.shared.saveProject()
        }
        let saveAsAction = UIAction(title: "Save as...", image: nil) { _ in
            EditorModel.shared.saveProjectAs = true
        }
        
        let newAction = UIAction(title: "New", image: nil) { _ in
            EditorModel.shared.newProject()
        }
        let loadAction = UIAction(title: "Open...", image: nil) { _ in
            //EditorModel.shared.loadProject()
            self.showDocPicker = true
        }
        
        let recentActions = EditorModel.shared.recentProjects.map{ item in
            let recentAction = UIAction(title: item, image: nil) { _ in
                EditorModel.shared.loadProject(item )
               
            }
            return recentAction
        }
         
        let recentMenu = UIMenu(title: "Open recent", children: recentActions.reversed())
       
        let exportAction = UIAction(title: "Export to gallery", image: nil) { _ in
            EditorModel.shared.exportToGallery()
        }
        
        // Creiamo il sottomenu "File" con le azioni definite sopra
        let fileMenu = UIMenu(title: "File", children: [newAction,loadAction,recentMenu, saveAction, saveAsAction,exportAction].reversed())
        
        // --- Sottomenu "Layers" ---
        
        
        /*let newLayerAction = UIAction(title: "Add new", image: nil) { _ in
         EditorModel.shared.addLayer()
         }*/
        
        /*
        let undoAction = UIAction(title: "Undo", image: nil) { _ in
            
            EditorModel.shared.undo()
            
        }
        let redoAction = UIAction(title: "Redo", image: nil) { _ in
            
            EditorModel.shared.redo()
            
        }*/
        
        let zoomToFitAction = UIAction(title: "Zoom to fit", image: nil) { _ in
            
            EditorModel.shared.zoomToFit()
            
        }
        
        let editMenu = UIMenu(title: "Edit", children: [zoomToFitAction].reversed())
        
        // Creiamo il sottomenu "Layers"
        //let layersMenu = UIMenu(title: "Layers", children: [newLayerAction, viewLayersAction].reversed())
        let layersMenu = UIAction(title: "Layers", image: nil) { _ in
            
            EditorModel.shared.showLayerEditorDetail = true
            
        }
        // --- Menu Principale e Bottone ---
        
        // Creiamo il menu principale che contiene i nostri due sottomenu
        self.mainMenu = UIMenu(title: "", options: .displayInline, children: [fileMenu,editMenu,layersMenu].reversed())
        
       
        // Assegniamo il bottone come accessoryItem del picker
    }
}
