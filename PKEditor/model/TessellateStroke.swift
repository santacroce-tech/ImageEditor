//
//  File.swift
//  PKEditor
//
//  Created by Luca Rocchi on 15/06/25.
//

import Foundation
import PencilKit
import SVGKit

class PathScribe {
    var points: [CGPoint] = []
    
    var allSubpaths: [[CGPoint]] = []
    var currentSubpathPoints: [CGPoint] = []
      
    var lastPoint: CGPoint = .zero // Teniamo traccia dell'ultimo punto per le curve
}

struct TessellateStroke {
    static let steps = 15 // Più step = maggiore dettaglio

    static func tessellateQuadCurve(from start: CGPoint, control: CGPoint, to end: CGPoint, scribe: PathScribe) {
        for i in 1...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let a = pow(1.0 - t, 2.0)
            let b = 2.0 * (1.0 - t) * t
            let c = pow(t, 2.0)
            let x = a * start.x + b * control.x + c * end.x
            let y = a * start.y + b * control.y + c * end.y
            scribe.points.append(CGPoint(x: x, y: y))
        }
    }

    /// Calcola i punti lungo una curva di Bézier cubica.
    static func tessellateCubicCurve(from start: CGPoint, control1: CGPoint, control2: CGPoint, to end: CGPoint, scribe: PathScribe) {
        for i in 1...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let a = pow(1.0 - t, 3.0)
            let b = 3.0 * pow(1.0 - t, 2.0) * t
            let c = 3.0 * (1.0 - t) * pow(t, 2.0)
            let d = pow(t, 3.0)
            let x = a * start.x + b * control1.x + c * control2.x + d * end.x
            let y = a * start.y + b * control1.y + c * control2.y + d * end.y
            scribe.points.append(CGPoint(x: x, y: y))
        }
    }


}

extension TessellateStroke {
    
    // Puoi modificare 'steps' qui per controllare la precisione di TUTTE le forme.
  /*
    static func tessellateQuadCurve2(from start: CGPoint, control: CGPoint, to end: CGPoint, scribe: PathScribe) {
        for i in 1...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let a = pow(1.0 - t, 2.0)
            let b = 2.0 * (1.0 - t) * t
            let c = pow(t, 2.0)
            let x = a * start.x + b * control.x + c * end.x
            let y = a * start.y + b * control.y + c * end.y
            
            // --- CORREZIONE CHIAVE ---
            // Aggiungiamo i punti al sotto-tracciato corrente, non a un altro array.
            scribe.currentSubpathPoints.append(CGPoint(x: x, y: y))
        }
    }

    static func tessellateCubicCurve2(from start: CGPoint, control1: CGPoint, control2: CGPoint, to end: CGPoint, scribe: PathScribe) {
        for i in 1...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let a = pow(1.0 - t, 3.0)
            let b = 3.0 * pow(1.0 - t, 2.0) * t
            let c = 3.0 * (1.0 - t) * pow(t, 2.0)
            let d = pow(t, 3.0)
            let x = a * start.x + b * control1.x + c * control2.x + d * end.x
            let y = a * start.y + b * control1.y + c * control2.y + d * end.y
            
            // --- CORREZIONE CHIAVE ---
            // Aggiungiamo i punti al sotto-tracciato corrente, non a un altro array.
            scribe.currentSubpathPoints.append(CGPoint(x: x, y: y))
        }
    }
    */
    
    static func tessellateQuadCurve2(from start: CGPoint, control: CGPoint, to end: CGPoint) -> [CGPoint] {
          var points: [CGPoint] = []
          for i in 1...steps {
              let t = CGFloat(i) / CGFloat(steps)
              let a = pow(1.0 - t, 2.0)
              let b = 2.0 * (1.0 - t) * t
              let c = pow(t, 2.0)
              let x = a * start.x + b * control.x + c * end.x
              let y = a * start.y + b * control.y + c * end.y
              points.append(CGPoint(x: x, y: y))
          }
          return points
      }

      static func tessellateCubicCurve2(from start: CGPoint, control1: CGPoint, control2: CGPoint, to end: CGPoint) -> [CGPoint] {
          var points: [CGPoint] = []
          for i in 1...steps {
              let t = CGFloat(i) / CGFloat(steps)
              let a = pow(1.0 - t, 3.0)
              let b = 3.0 * pow(1.0 - t, 2.0) * t
              let c = 3.0 * (1.0 - t) * pow(t, 2.0)
              let d = pow(t, 3.0)
              let x = a * start.x + b * control1.x + c * control2.x + d * end.x
              let y = a * start.y + b * control1.y + c * control2.y + d * end.y
              points.append(CGPoint(x: x, y: y))
          }
          return points
      }
    
}
