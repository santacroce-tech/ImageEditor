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
        
        guard let svgImage = SVGKImage(named: svgName),
              let shapeLayer = findFirstVisibleShapeLayer(in: svgImage.caLayerTree),
              let path = shapeLayer.path else {
            return []
        }
        let pathBoundingBox = path.boundingBox
        var transform = CGAffineTransform.identity
        let offsetX = -pathBoundingBox.midX
        let offsetY = -pathBoundingBox.midY
        transform = transform.translatedBy(x: center.x, y: center.y)
        transform = transform.scaledBy(x: scale, y: scale)
        transform = transform.translatedBy(x: offsetX, y: offsetY)
        guard let transformedPath = path.copy(using: &transform) else { return [] }
        
        // 1. Dividiamo il path trasformato in un array di sotto-tracciati (ognuno è un [CGPoint])
        let subpaths = TessellateStroke.getSubpaths(from: transformedPath)
        
        var finalStrokes: [PKStroke] = []
        let ink = PKInk(.pen, color: color)
        
        // 2. Iteriamo su ogni sotto-tracciato trovato
        for pointArray in subpaths {
            // 3. Creiamo uno stroke per ciascuno
            if let newStroke = TessellateStroke.createStrokeFromSubpath(points: pointArray, ink: ink, width: width) {
                finalStrokes.append(newStroke)
            }
        }
        
        return finalStrokes
    }
   
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
}

