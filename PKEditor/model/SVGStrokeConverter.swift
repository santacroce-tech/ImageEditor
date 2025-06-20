//
//  SVGStrokeConverter.swift
//  PKEditor
//
//  Created by Luca Rocchi on 14/06/25.
//

import Foundation
import PencilKit
import SVGKit

struct SVGStrokeConverter {
    static func createStrokes(fromSVGNamed svgName: String, at center: CGPoint, color: UIColor, width: CGFloat, scale: CGFloat) -> [PKStroke] {
        
        /* guard let path = CGPath.fromSvgPath(svgPath: svgName) else {
         print("Errore: Impossibile caricare il file SVG '\(svgName)'")
         return nil
         }*/
        
        guard let svgImage = SVGKImage(named: svgName) else {
            print("Errore: Impossibile caricare il file SVG '\(svgName)'")
            return []
        }
        //svgImage.
        guard let shapeLayer = findFirstVisibleShapeLayer(in: svgImage.caLayerTree), let path = shapeLayer.path else {
            print("Errore: Nessun path visibile trovato nel file SVG.")
            return []
        }
        
        let pathBoundingBox = path.boundingBox
        
        let offsetX = -pathBoundingBox.origin.x - (pathBoundingBox.width / 2)
        let offsetY = -pathBoundingBox.origin.y - (pathBoundingBox.height / 2)
        
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: center.x, y: center.y)
        transform = transform.scaledBy(x: scale, y: scale)
        transform = transform.translatedBy(x: offsetX, y: offsetY)
        
        
        guard let transformedPath = path.copy(using: &transform) else { return [] }
        
        let cgPoints = getPoints(from: transformedPath)
        guard !cgPoints.isEmpty else { return [] }
        
        var finalStrokes: [PKStroke] = []
        let ink = PKInk(.pen, color: color)
        
        for i in 0..<(cgPoints.count - 1) {
            
            let startPoint = cgPoints[i]
            let endPoint = cgPoints[i+1]
            
            let strokePoints = [
                PKStrokePoint(location: startPoint, timeOffset: 0, size: CGSize(width: width, height: width), opacity: 1, force: 1, azimuth: 0, altitude: .pi/2),
                PKStrokePoint(location: endPoint, timeOffset: 0.01, size: CGSize(width: width, height: width), opacity: 1, force: 1, azimuth: 0, altitude: .pi/2)
            ]
            
            // Creiamo il PKPath e il PKStroke per questo singolo segmento
            let strokePath = PKStrokePath(controlPoints: strokePoints, creationDate: Date())
            let stroke = PKStroke(ink: ink, path: strokePath)
            
            finalStrokes.append(stroke)
        }
        
        return finalStrokes
    }
    
    
    static func createStroke(fromSVGNamed svgName: String, at center: CGPoint, color: UIColor, width: CGFloat, scale: CGFloat) -> PKStroke? {
        
        /* guard let path = CGPath.fromSvgPath(svgPath: svgName) else {
         print("Errore: Impossibile caricare il file SVG '\(svgName)'")
         return nil
         }*/
        
        guard let svgImage = SVGKImage(named: svgName) else {
            print("Errore: Impossibile caricare il file SVG '\(svgName)'")
            return nil
        }
        //svgImage.
        guard let shapeLayer = findFirstVisibleShapeLayer(in: svgImage.caLayerTree), let path = shapeLayer.path else {
            print("Errore: Nessun path visibile trovato nel file SVG.")
            return nil
        }
        
        let pathBoundingBox = path.boundingBox
        
        let offsetX = -pathBoundingBox.origin.x - (pathBoundingBox.width / 2)
        let offsetY = -pathBoundingBox.origin.y - (pathBoundingBox.height / 2)
        
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: center.x, y: center.y)
        transform = transform.scaledBy(x: scale, y: scale)
        transform = transform.translatedBy(x: offsetX, y: offsetY)
        
        
        guard let transformedPath = path.copy(using: &transform) else { return nil }
        
        let cgPoints = getPoints(from: transformedPath)
        guard !cgPoints.isEmpty else { return nil }
        
        var strokePoints: [PKStrokePoint] = []
        for (i, point) in cgPoints.enumerated() {
            let strokePoint = PKStrokePoint(
                location: point, timeOffset: TimeInterval(i) * 0.01, size: CGSize(width: width, height: width),
                opacity: 1, force: 1, azimuth: 0, altitude: .pi / 2
            )
            strokePoints.append(strokePoint)
        }
        
        let finalPath = PKStrokePath(controlPoints: strokePoints, creationDate: Date())
        let ink = PKInk(.pen, color: color)
        return PKStroke(ink: ink, path: finalPath)
    }
    
    
}



extension SVGStrokeConverter {
    private static func findFirstVisibleShapeLayer(in layer: CALayer) -> CAShapeLayer? {
        if let shapeLayer = layer as? CAShapeLayer,
           shapeLayer.opacity > 0,
           let path = shapeLayer.path, !path.isEmpty {
            return shapeLayer
        }
        
        guard let sublayers = layer.sublayers else { return nil }
        
        for sublayer in sublayers {
            if let shapeLayer = findFirstVisibleShapeLayer(in: sublayer) {
                return shapeLayer
            }
        }
        
        return nil
    }
    
    
    
    /// Funzione principale che ora gestisce correttamente la conversione
    private static func getPoints(from path: CGPath) -> [CGPoint] {
        let scribe = PathScribe()
        let scribePointer = Unmanaged.passUnretained(scribe).toOpaque()
        path.apply(info: scribePointer, function: pathElementApplier)
        return scribe.points
    }
    
    /// La funzione C-style che ora CALCOLA i punti sulle curve
    private static let pathElementApplier: @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CGPathElement>) -> Void = { info, elementPtr in
        
        guard let scribePointer = info else { return }
        let scribe = Unmanaged<PathScribe>.fromOpaque(scribePointer).takeUnretainedValue()
        let element = elementPtr.pointee
        
        switch element.type {
        case .moveToPoint:
            let point = element.points[0]
            scribe.points.append(point)
            scribe.lastPoint = point
            
        case .addLineToPoint:
            let point = element.points[0]
            scribe.points.append(point)
            scribe.lastPoint = point
            
        case .addQuadCurveToPoint:
            let control = element.points[0]
            let end = element.points[1]
            TessellateStroke.tessellateQuadCurve(from: scribe.lastPoint, control: control, to: end, scribe: scribe)
            scribe.lastPoint = end
            
        case .addCurveToPoint:
            let control1 = element.points[0]
            let control2 = element.points[1]
            let end = element.points[2]
            TessellateStroke.tessellateCubicCurve(from: scribe.lastPoint, control1: control1, control2: control2, to: end, scribe: scribe)
            scribe.lastPoint = end
            
        case .closeSubpath:
            if let firstPoint = scribe.points.first {
                scribe.points.append(firstPoint)
                scribe.lastPoint = firstPoint
            }
            
        @unknown default:
            break
        }
    }
    
}

extension SVGStrokeConverter {
    
    /// Il metodo pubblico principale. Carica un SVG e lo converte in un array di PKStroke, uno per ogni sotto-tracciato.
    static func createStrokes2(fromSVGNamed svgName: String, at center: CGPoint, color: UIColor, width: CGFloat, scale: CGFloat) -> [PKStroke] {
        
        guard let svgImage = SVGKImage(named: svgName),
              let shapeLayer = findFirstVisibleShapeLayer(in: svgImage.caLayerTree),
              let path = shapeLayer.path else {
            return []
        }

        // Calcoliamo e applichiamo la trasformazione una sola volta al path principale
        let pathBoundingBox = path.boundingBox
        var transform = CGAffineTransform.identity
        let offsetX = -pathBoundingBox.midX
        let offsetY = -pathBoundingBox.midY
        transform = transform.translatedBy(x: center.x, y: center.y)
        transform = transform.scaledBy(x: scale, y: scale)
        transform = transform.translatedBy(x: offsetX, y: offsetY)
        guard let transformedPath = path.copy(using: &transform) else { return [] }
        
        // 1. Dividiamo il path trasformato in un array di sotto-tracciati (ognuno è un [CGPoint])
        let subpaths = getSubpaths(from: transformedPath)
        
        var finalStrokes: [PKStroke] = []
        let ink = PKInk(.pen, color: color)
        
        // 2. Iteriamo su ogni sotto-tracciato trovato
        for pointArray in subpaths {
            // 3. Creiamo uno stroke per ciascuno
            if let newStroke = createStrokeFromSubpath(points: pointArray, ink: ink, width: width) {
                finalStrokes.append(newStroke)
            }
        }
        
        return finalStrokes
    }
    
    // MARK: - Funzioni Helper

    /// Crea un singolo PKStroke da un array di punti.
    private static func createStrokeFromSubpath(points: [CGPoint], ink: PKInk, width: CGFloat) -> PKStroke? {
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
    private static func getSubpaths(from path: CGPath) -> [[CGPoint]] {
        let scribe = PathScribe()
        let scribePointer = Unmanaged.passUnretained(scribe).toOpaque()
        path.apply(info: scribePointer, function: pathElementApplier2)
        
        // Aggiunge l'ultimo sotto-tracciato rimasto dopo la fine del ciclo
        if !scribe.currentSubpathPoints.isEmpty {
            scribe.allSubpaths.append(scribe.currentSubpathPoints)
        }
        
        return scribe.allSubpaths
    }

    /// La funzione C-style che esegue la divisione dei tracciati.
    ///
    /*
    private static let pathElementApplier2: @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CGPathElement>) -> Void = { info, elementPtr in
        guard let scribePointer = info else { return }
        let scribe = Unmanaged<PathScribe>.fromOpaque(scribePointer).takeUnretainedValue()
        let element = elementPtr.pointee
        
        switch element.type {
        case .moveToPoint:
            // Un 'moveToPoint' indica l'inizio di un NUOVO sotto-tracciato.
            // Prima salviamo il sotto-tracciato precedente, se esiste.
            if !scribe.currentSubpathPoints.isEmpty {
                scribe.allSubpaths.append(scribe.currentSubpathPoints)
            }
            // Iniziamo un nuovo sotto-tracciato con il nuovo punto.
            let point = element.points[0]
            scribe.currentSubpathPoints = [point]
            scribe.lastPoint = point
            
        case .addLineToPoint:
            let point = element.points[0]
            scribe.currentSubpathPoints.append(point)
            scribe.lastPoint = point
            
        case .addQuadCurveToPoint:
            let control = element.points[0]
            let end = element.points[1]
            TessellateStroke.tessellateQuadCurve2(from: scribe.lastPoint, control: control, to: end, scribe: scribe)
            scribe.lastPoint = end

        case .addCurveToPoint:
            let control1 = element.points[0]
            let control2 = element.points[1]
            let end = element.points[2]
            TessellateStroke.tessellateCubicCurve2(from: scribe.lastPoint, control1: control1, control2: control2, to: end, scribe: scribe)
            scribe.lastPoint = end

        case .closeSubpath:
            if let firstPoint = scribe.currentSubpathPoints.first {
                scribe.currentSubpathPoints.append(firstPoint)
            }
        @unknown default:
            break
        }
    }
    */
    private static let pathElementApplier2: @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CGPathElement>) -> Void = { info, elementPtr in
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
            let tessellatedPoints = TessellateStroke.tessellateQuadCurve2(from: scribe.lastPoint, control: control, to: end)
            scribe.currentSubpathPoints.append(contentsOf: tessellatedPoints)
            scribe.currentSubpathPoints.append(end) // <-- Duplichiamo il vertice finale della curva
            scribe.lastPoint = end

        case .addCurveToPoint:
            let control1 = element.points[0]
            let control2 = element.points[1]
            let end = element.points[2]
            let tessellatedPoints = TessellateStroke.tessellateCubicCurve2(from: scribe.lastPoint, control1: control1, control2: control2, to: end)
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
}
