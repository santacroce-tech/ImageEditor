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
    
    static func tessellateQuadCurve(from start: CGPoint, control: CGPoint, to end: CGPoint) -> [CGPoint] {
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

      static func tessellateCubicCurve(from start: CGPoint, control1: CGPoint, control2: CGPoint, to end: CGPoint) -> [CGPoint] {
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
    
    static let pathElementApplier: @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CGPathElement>) -> Void = { info, elementPtr in
        guard let scribePointer = info else { return }
        let scribe = Unmanaged<PathScribe>.fromOpaque(scribePointer).takeUnretainedValue()
        let element = elementPtr.pointee
        
        switch element.type {
        case .moveToPoint:
            if !scribe.currentSubpathPoints.isEmpty {
                scribe.allSubpaths.append(scribe.currentSubpathPoints)
            }
            let point = element.points[0]
            // Iniziamo un nuovo sotto-tracciato
            scribe.currentSubpathPoints = [point, point] // <-- Duplichiamo il primo punto
            scribe.lastPoint = point
            
        case .addLineToPoint:
            let point = element.points[0]
            scribe.currentSubpathPoints.append(point)
            scribe.currentSubpathPoints.append(point) // <-- Duplichiamo il vertice
            scribe.lastPoint = point
            
        case .addQuadCurveToPoint:
            let control = element.points[0]
            let end = element.points[1]
            let tessellatedPoints = TessellateStroke.tessellateQuadCurve(from: scribe.lastPoint, control: control, to: end)
            scribe.currentSubpathPoints.append(contentsOf: tessellatedPoints)
            scribe.currentSubpathPoints.append(end) // <-- Duplichiamo il vertice finale della curva
            scribe.lastPoint = end

        case .addCurveToPoint:
            let control1 = element.points[0]
            let control2 = element.points[1]
            let end = element.points[2]
            let tessellatedPoints = TessellateStroke.tessellateCubicCurve(from: scribe.lastPoint, control1: control1, control2: control2, to: end)
            scribe.currentSubpathPoints.append(contentsOf: tessellatedPoints)
            scribe.currentSubpathPoints.append(end) // <-- Duplichiamo il vertice finale della curva
            scribe.lastPoint = end

        case .closeSubpath:
            if let firstPoint = scribe.currentSubpathPoints.first {
                scribe.currentSubpathPoints.append(firstPoint)
                scribe.currentSubpathPoints.append(firstPoint) // <-- Duplichiamo anche la chiusura
            }
            if !scribe.currentSubpathPoints.isEmpty {
                scribe.allSubpaths.append(scribe.currentSubpathPoints)
            }
            scribe.currentSubpathPoints = []
            
        @unknown default:
            break
        }
    }

    
    
    /// Crea un singolo PKStroke da un array di punti.
    static func createStrokeFromSubpath(points: [CGPoint], ink: PKInk, width: CGFloat) -> PKStroke? {
        guard points.count > 1 else { return nil }
        
        var strokePoints: [PKStrokePoint] = []
        for (i, point) in points.enumerated() {
            let strokePoint = PKStrokePoint(
                location: point, timeOffset: TimeInterval(i) * 0.01, size: CGSize(width: width, height: width),
                opacity: 1, force: 1, azimuth: 0, altitude: .pi / 2
            )
            strokePoints.append(strokePoint)
        }
        
        let strokePath = PKStrokePath(controlPoints: strokePoints, creationDate: Date())
        return PKStroke(ink: ink, path: strokePath)
    }
    
    /// Analizza un CGPath e lo divide in sotto-tracciati.
    static func getSubpaths(from path: CGPath) -> [[CGPoint]] {
        let scribe = PathScribe()
        let scribePointer = Unmanaged.passUnretained(scribe).toOpaque()
        path.apply(info: scribePointer, function: TessellateStroke.pathElementApplier)
        
        // Aggiunge l'ultimo sotto-tracciato rimasto dopo la fine del ciclo
        if !scribe.currentSubpathPoints.isEmpty {
            scribe.allSubpaths.append(scribe.currentSubpathPoints)
        }
        
        return scribe.allSubpaths
    }


}
