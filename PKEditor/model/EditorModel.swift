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
@MainActor
class EditorModel: NSObject,ObservableObject {
    static let shared = EditorModel()
    @Published var layers: [LayerCanvasModel] = [] // Rimuovi LayerListModel
    @Published var animalStampWrapper = AnimalStampWrapper()
    // let undoManager = UndoManager()
    @Published var projectID = UUID()
    
    //@Published var canUndo: Bool = false
    //@Published var canRedo: Bool = false
    //var activeUndoManager: UndoManager?
    private var cancellables = Set<AnyCancellable>()
    @Published var projectName: String = "drawingProject"
    @Published var isShowingAccessorySheet: Bool = false
    @Published var saveProjectAs: Bool = false
    @Published var showLayerEditorDetail: Bool = false
    
    @Published var activeCanvasId: Int = 1
    @Published var sharedContentOffset: CGPoint = .zero
    private var canvasViews: [Int: PKCanvasView?] = [:]

    override init() {
        super.init()
        addLayer()
        //addLayer()
        //addLayer()
        activeCanvasId = 1
    }
    
    func addLayer() {
        let canvasId = layers.count + 1
        let layer = LayerCanvasModel(currentCanvasId: canvasId)
        layers.append(layer)
        activeCanvasId = canvasId
    }
    
     /*
    func undo() {
        activeUndoManager?.undo()
        //objectWillChange.send()
    }
    
    func redo() {
        activeUndoManager?.redo()
        // Notifichiamo alla UI che lo stato potrebbe essere cambiato
        //objectWillChange.send()
    }
      */
   
    
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

        // --- LA SOLUZIONE DEFINITIVA ---
        // Invece di modificare lo stroke direttamente, diciamo al disegno
        // di applicare la trasformazione per noi sull'array di stroke che gli passiamo.
        // In questo caso, l'array contiene solo il nostro ultimo stroke.
        //drawing.transform(strokes: [lastStroke], with: transform)
        drawing.transform(using:transform)
        // Riassegnamo il disegno modificato in modo sicuro.
        layers[layerIndex].drawing = drawing
        
        // Non è più necessario objectWillChange.send() perché la riassegnazione
        // di un @Published struct notificherà la vista.
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
    
    /// Salva l'array di layer corrente in un file JSON.
    func saveProject(name:String? = nil) {
        let newName = name ?? projectName
        
        let filename = "\(newName).json"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self.layers)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            print("✅ Progetto salvato con successo in: \(url.path)")
            projectName = newName
        } catch {
            print("❌ Errore durante il salvataggio del progetto: \(error.localizedDescription)")
        }
    }
    
    /// Carica un progetto da un file JSON e sostituisce i layer correnti.
    func loadProject(from name: String = "drawingProject") {
        let filename = "\(name).json"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        
        // Prima di caricare, registriamo lo stato attuale per l'undo
        let currentLayers = self.layers
        /*activeUndoManager?.registerUndo(withTarget: self) { target in
            target.layers = currentLayers
        }*/
        
        canvasViews.removeAll()
        //EditorModel.shared.unregisterCanvasView(forLayerID: coordinator.parent.model.id)

        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: url)
            let loadedLayers = try decoder.decode([LayerCanvasModel].self, from: data)
            self.layers = loadedLayers
            activeCanvasId = 1
            projectName = name
            self.projectID = UUID()
       
            print("✅ Progetto caricato con successo.")
        } catch {
            print("❌ Errore durante il caricamento del progetto: \(error.localizedDescription)")
        }
    }
    
    /*
    func setActiveUndoManager(_ undoManager: UndoManager?) {
          // Non fare nulla se è lo stesso manager di prima
          guard activeUndoManager !== undoManager else { return }
          
          // Rimuoviamo gli osservatori dal vecchio manager
          cancellables.removeAll()
          
          activeUndoManager = undoManager
          
          // Se c'è un nuovo manager attivo, ci mettiamo in ascolto delle sue notifiche
          if let manager = activeUndoManager {
              let notificationNames: [Notification.Name] = [
                  .NSUndoManagerCheckpoint,
                  .NSUndoManagerDidUndoChange,
                  .NSUndoManagerDidRedoChange,
                  .NSUndoManagerWillCloseUndoGroup
              ]
              
              for name in notificationNames {
                  NotificationCenter.default.publisher(for: name, object: manager)
                      .sink { [weak self] _ in
                          self?.updateUndoButtonState()
                      }
                      .store(in: &cancellables)
              }
          }
          
          // Aggiorniamo lo stato dei bottoni subito
          updateUndoButtonState()
      }
    
    private func updateUndoButtonState() {
        DispatchQueue.main.async {
            self.canUndo = self.activeUndoManager?.canUndo ?? false
            self.canRedo = self.activeUndoManager?.canRedo ?? false
        }
    }*/
    
    
    func exportVisibleLayersAsSingleImage() {
         
         // 1. Filtra per ottenere solo i layer visibili e con qualcosa disegnato
         let visibleLayers = self.layers.filter { $0.visible && !$0.drawing.bounds.isEmpty }
         
         guard !visibleLayers.isEmpty else {
             print("Nessun layer visibile con contenuto da esportare.")
             return
         }
         
         // 2. Calcola il rettangolo totale che contiene tutti i disegni
         let totalBounds = visibleLayers.reduce(CGRect.null) { (result, layer) -> CGRect in
             return result.union(layer.drawing.bounds)
         }
         
         guard !totalBounds.isNull, totalBounds.width > 0, totalBounds.height > 0 else {
             print("Dimensioni del disegno non valide.")
             return
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
         
         // 4. Salva l'immagine finale nella galleria fotografica
         UIImageWriteToSavedPhotosAlbum(compositeImage, self, #selector(imageSaveCompletion), nil)
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
}
