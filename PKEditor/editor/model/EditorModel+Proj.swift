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

struct ProjectItem {
    let name: String
    let url: URL
    let image:URL
}

struct ProjectData: Codable {
    let contentSize: CGSize
    let contentOffset: CGPoint
    let backgroundColor:UIColor
    let backgroundImage:UIImage?

    let layers: [LayerCanvasModel]
    
    enum CodingKeys: String, CodingKey {
           case contentSize
           case contentOffset
            case backgroundColorData // Salveremo il colore come Data
            case backgroundImageData
            case layers
       }
    
    // 2. Implementiamo l'inizializzatore per la decodifica (da JSON a oggetto).
      init(from decoder: Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          
          // Decodifichiamo i tipi semplici come al solito
          contentSize = try container.decode(CGSize.self, forKey: .contentSize)
          contentOffset = try container.decode(CGPoint.self, forKey: .contentOffset)
          layers = try container.decode([LayerCanvasModel].self, forKey: .layers)
          
          do {
              let colorData = try container.decode(Data.self, forKey: .backgroundColorData)
              backgroundColor = UIColor.decode(from: colorData) ?? .black
          }catch let error {
              print("initdecoder")
              print(error)
              backgroundColor = .white
          }
          if let imageData = try container.decodeIfPresent(Data.self, forKey: .backgroundImageData) {
              self.backgroundImage = UIImage(data: imageData)
          } else {
              self.backgroundImage = nil
          }
      }
      
      // 3. Implementiamo la funzione per la codifica (da oggetto a JSON).
      func encode(to encoder: Encoder) throws {
          var container = encoder.container(keyedBy: CodingKeys.self)
          
          // Codifichiamo i tipi semplici come al solito
          try container.encode(contentSize, forKey: .contentSize)
          try container.encode(contentOffset, forKey: .contentOffset)
          try container.encode(layers, forKey: .layers)
          
          // Per il colore, usiamo la nostra funzione helper per convertirlo in Data
          // prima di codificarlo.
          if let colorData = backgroundColor.encode() {
              try container.encode(colorData, forKey: .backgroundColorData)
          }
          if let imageData = backgroundImage?.pngData() {
                     try container.encode(imageData, forKey: .backgroundImageData)
                 }
         
      }
      
      // Un init personalizzato per quando creiamo i dati da salvare
      init(contentSize: CGSize, contentOffset: CGPoint, backgroundColor: UIColor, backgroundImage: UIImage?,layers: [LayerCanvasModel]) {
          self.contentSize = contentSize
          self.contentOffset = contentOffset
          self.backgroundColor = backgroundColor
          self.backgroundImage = backgroundImage
          self.layers = layers
      }
}

extension EditorModel {
    
    func getDocumentsDirectory() -> URL {
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
        
        let projectData = ProjectData(contentSize: self.contentSize, contentOffset: self.contentOffset,backgroundColor: backgroundColor,backgroundImage:self.backgroundImage,layers: self.layers)
        
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
        //canvasViews.removeAll()
        layers.removeAll()
        projectName = defProjectName
        addLayer()
        activeCanvasId = 1
        backgroundImage = nil
        self.projectID = UUID()
        contentOffset = .zero
        contentSize = CGSize(width: 1024, height: 1024)
        showTextInput = false
        backgroundColor = .clear
        
    }
    
    /// Carica un progetto da un file JSON e sostituisce i layer correnti.
    func loadProject(_ name: String = "drawingProject") {
        let filename = "\(name).json"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        loadProject(from: url)
       
        
    }
    
    func loadProject(from url: URL) {
        let name = url.deletingPathExtension().lastPathComponent
        //canvasViews.removeAll()
      
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: url)
            
            let loadedProject = try decoder.decode(ProjectData.self, from: data)
            self.contentSize = loadedProject.contentSize
            self.contentOffset = loadedProject.contentOffset
            self.layers = loadedProject.layers
            self.backgroundColor = loadedProject.backgroundColor
            self.backgroundImage = loadedProject.backgroundImage
          
            contentOffset = .zero
            
            activeCanvasId = 1
            projectName = name
            self.projectID = UUID()
            showTextInput = false
        
            print("✅ Progetto caricato con successo.")
        } catch {
            print("❌ Errore durante il caricamento del progetto: \(error.localizedDescription)")
        }
    }
    
    func exportToGallery()  {
        if let compositeImage = renderLayers() {
            UIImageWriteToSavedPhotosAlbum(compositeImage, self, #selector(imageSaveCompletion), nil)
            EditorModel.shared.showGallery = true
        }
    }
    
    
    func renderLayers() -> UIImage? {
        
        let renderFrame = CGRect(origin: .zero, size: self.contentSize)
            
        // Controlliamo che la dimensione sia valida.
        guard renderFrame.width > 0, renderFrame.height > 0 else {
            print("Dimensioni del contentSize non valide per l'esportazione.")
            return nil
        }
      
        
         let visibleLayers = self.layers.filter { $0.visible && !$0.drawing.bounds.isEmpty }
         
         guard !visibleLayers.isEmpty else {
             print("Nessun layer visibile con contenuto da esportare.")
             return nil
         }
         /*
         let totalBounds = visibleLayers.reduce(CGRect.null) { (result, layer) -> CGRect in
             return result.union(layer.drawing.bounds)
         }
         
         guard !totalBounds.isNull, totalBounds.width > 0, totalBounds.height > 0 else {
             print("Dimensioni del disegno non valide.")
             return nil
         }
         
         let renderer = UIGraphicsImageRenderer(bounds: totalBounds)
         */
        
         let renderer = UIGraphicsImageRenderer(size: contentSize)
         let compositeImage = renderer.image { context in
             // Disegniamo i layer uno sopra l'altro, dal basso verso l'alto
             
             for layer in self.layers {
                 // Se il layer non è visibile, lo saltiamo
                 guard layer.visible else { continue }
                 
                 if layer.index == 0 {
                     self.backgroundColor.setFill()
                     context.fill(renderFrame)
                 }
              
                 // Generiamo l'immagine per questo singolo layer
                 let layerImage = layer.drawing.image(from: renderFrame, scale: UIScreen.main.scale)
                 
                 // Disegniamo l'immagine nel contesto, rispettando la sua opacità
                 layerImage.draw(in: renderFrame, blendMode: .normal, alpha: layer.opacity)
             }
         }
         return compositeImage
       
     }

    @objc func imageSaveCompletion(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
         if let error = error {
             print("❌ Errore nel salvataggio dell'immagine composita: \(error.localizedDescription)")
         } else {
             print("✅ Immagine composita salvata con successo nella galleria!")
         }
     }
    
    
    func getRecentProjects() -> [ProjectItem] {
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
            
            
            var projectItems:[ProjectItem] = sortedFiles.map {
                
                let deletedExt = $0.url.deletingPathExtension()
                let projectItem =  ProjectItem(name:deletedExt.lastPathComponent,url: $0.url,image: $0.url.appendingPathExtension("png"))
                return projectItem
            }
            
            print("✅ Trovati progetti recenti: \(projectItems)")
            projectItems = Array(projectItems.prefix(10))
            return projectItems
            
        } catch {
            print("❌ Errore durante la lettura dei file: \(error.localizedDescription)")
            return []
        }
    }
    
    func publish(){
        if let image = renderLayers() {
            saveProject()
            onPublish?(image)
        }
    }
    
    func exit(){
        saveProject()
        onExit?()
        
       
    }
    
    func newProjectFromImage(_ image: UIImage) {
        // Resetta lo stato del progetto
        layers.removeAll()
        contentOffset = .zero
        zoomScale = 1.0
        
        // Imposta la dimensione della tela sulla dimensione dell'immagine
        self.contentSize = image.size
        
        // Salva l'immagine nel modello. Le viste reagiranno a questo cambiamento.
        self.backgroundImage = image
        self.backgroundColor = .clear
       
        // Aggiunge il primo layer
        addLayer()
        activeCanvasId = layers.first?.id ?? 1
        
        // Forza la ricostruzione della UI
        projectID = UUID()
    }
}


