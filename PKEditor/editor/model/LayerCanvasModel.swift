//
//  LayerModel.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//

import Foundation
//@MainActor
import PencilKit


class LayerCanvasModel:ObservableObject,Identifiable, Codable {
    @Published var visible = true
    @Published var opacity = 1.0
    @Published var currentCanvasId: Int 
    @Published var drawing: PKDrawing = PKDrawing()
    @Published var drawingPolicy: PKCanvasViewDrawingPolicy = .anyInput
    @Published var pickerVisibility = false
    var canvas:PKCanvasView?
    var index = 0
    var id:Int {currentCanvasId}
    
    init(currentCanvasId:Int){
        self.currentCanvasId = currentCanvasId
    }
    
    enum CodingKeys: String, CodingKey {
           case currentCanvasId
           case drawing
           case opacity
           case visible
           // Non salviamo drawingPolicy e pickerVisibility per semplicità,
           // ma potremmo aggiungerli se necessario.
       }

       // 3. Aggiungiamo l'inizializzatore richiesto da Codable
       required init(from decoder: Decoder) throws {
           let container = try decoder.container(keyedBy: CodingKeys.self)
           self.currentCanvasId = try container.decode(Int.self, forKey: .currentCanvasId)
           self.drawing = try container.decode(PKDrawing.self, forKey: .drawing)
           self.opacity = try container.decode(Double.self, forKey: .opacity)
           self.visible = try container.decode(Bool.self, forKey: .visible)
       }
    // Nota: PKCanvasViewDrawingPolicy non è Codable, quindi l'ho escluso dal salvataggio.
    // Se necessario, dovremmo gestire la sua conversione manualmente (es. salvando il suo rawValue).
       // 4. Aggiungiamo la funzione di codifica richiesta da Codable
       func encode(to encoder: Encoder) throws {
           var container = encoder.container(keyedBy: CodingKeys.self)
           try container.encode(currentCanvasId, forKey: .currentCanvasId)
           try container.encode(drawing, forKey: .drawing)
           try container.encode(opacity, forKey: .opacity)
           try container.encode(visible, forKey: .visible)
       }
       
    func setDrawPolicy(policy:PKCanvasViewDrawingPolicy){
        drawingPolicy = policy
    }
    
    /*
    if UIDevice.current.userInterfaceIdiom == .pad {
          // Su iPad, accettiamo solo l'Apple Pencil per disegnare
          // e usiamo le dita per scorrere/zoomare.
          canvasView.drawingPolicy = .pencilOnly
      } else {
          // Su iPhone, dobbiamo per forza accettare il dito per disegnare.
          canvasView.drawingPolicy = .anyInput
      }
     
     func saveImage () {
         let image = canvas.drawing.image (from:
     canvas. drawing.bounds, scale: 1.0)
     UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
     ｝
     */
      
   
}
