//
//  DrawingShapesExample.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//


import Foundation
import PencilKit
import CoreGraphics // For CGPoint, CGRect etc.
//https://wwdcnotes.com/documentation/wwdcnotes/wwdc20-10148-inspect-modify-and-construct-pencilkit-drawings/
extension PKDrawing {

    /// Creates a PKStroke for a rectangle and adds it to the drawing.
    func addRectangleStroke(rect: CGRect, ink: PKInk) -> PKDrawing {
        var points: [PKStrokePoint] = []
        let numPointsPerSide: Int = 20 // Adjust for smoothness

        // Define a base for common stroke point properties
        let basePoint = PKStrokePoint(location: .zero, timeOffset: 0, size: CGSize(width: 3, height: 3), opacity: 1.0, force: 1.0, azimuth: 0, altitude: .pi / 2)

        // Generate points for each side of the rectangle
        // Top side (left to right)
        for i in 0..<numPointsPerSide {
            let x = rect.minX + CGFloat(i) / CGFloat(numPointsPerSide - 1) * rect.width
            let point = basePoint.copy(with: CGPoint(x: x, y: rect.minY), timeOffset: TimeInterval(i) * 0.001)
            points.append(point)
        }
        // Right side (top to bottom)
        for i in 0..<numPointsPerSide {
            let y = rect.minY + CGFloat(i) / CGFloat(numPointsPerSide - 1) * rect.height
            let point = basePoint.copy(with: CGPoint(x: rect.maxX, y: y), timeOffset: TimeInterval(numPointsPerSide + i) * 0.001)
            points.append(point)
        }
        // Bottom side (right to left)
        for i in 0..<numPointsPerSide {
            let x = rect.maxX - CGFloat(i) / CGFloat(numPointsPerSide - 1) * rect.width
            let point = basePoint.copy(with: CGPoint(x: x, y: rect.maxY), timeOffset: TimeInterval(2 * numPointsPerSide + i) * 0.001)
            points.append(point)
        }
        // Left side (bottom to top)
        for i in 0..<numPointsPerSide {
            let y = rect.maxY - CGFloat(i) / CGFloat(numPointsPerSide - 1) * rect.height
            let point = basePoint.copy(with: CGPoint(x: rect.minX, y: y), timeOffset: TimeInterval(3 * numPointsPerSide + i) * 0.001)
            points.append(point)
        }
        
        // Ensure the path closes (connects back to the start)
        if let firstPoint = points.first {
            let closingPoint = basePoint.copy(with: firstPoint.location, timeOffset: TimeInterval(4 * numPointsPerSide) * 0.001)
            points.append(closingPoint)
        }

        let path = PKStrokePath(controlPoints: points, creationDate: Date())
        let stroke = PKStroke(ink: ink, path: path)

        var newDrawing = self
        newDrawing.strokes.append(stroke)
        return newDrawing
    }

    /// Creates a PKStroke for a circle and adds it to the drawing.
    func addCircleStroke(center: CGPoint, radius: CGFloat, ink: PKInk) -> PKDrawing {
        var points: [PKStrokePoint] = []
        let numPoints: Int = 100 // Adjust for smoothness of the circle

        // Define a base for common stroke point properties
        let basePoint = PKStrokePoint(location: .zero, timeOffset: 0, size: CGSize(width: 3, height: 3), opacity: 1.0, force: 1.0, azimuth: 0, altitude: .pi / 2)

        for i in 0...numPoints {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(numPoints)
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            let location = CGPoint(x: x, y: y)
            let timeOffset = TimeInterval(i) * 0.001 // Small time offset for each point

            let point = basePoint.copy(with: location, timeOffset: timeOffset)
            points.append(point)
        }

        let path = PKStrokePath(controlPoints: points, creationDate: Date())
        let stroke = PKStroke(ink: ink, path: path)

        var newDrawing = self
        newDrawing.strokes.append(stroke)
        return newDrawing
    }
}

// Helper extension to copy PKStrokePoint with new values
extension PKStrokePoint {
    func copy(with newLocation: CGPoint? = nil, timeOffset: TimeInterval? = nil) -> PKStrokePoint {
        PKStrokePoint(
            location: newLocation ?? self.location,
            timeOffset: timeOffset ?? self.timeOffset,
            size: self.size,
            opacity: self.opacity,
            force: self.force,
            azimuth: self.azimuth,
            altitude: self.altitude
        )
    }
}


extension PKCanvasView {
    @objc func handleCustomTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        
        // Qui implementi la logica per disegnare la forma personalizzata
        drawCustomShape(at: location)
    }
    
    func drawCustomShape(at point: CGPoint) {
        // Esempio: disegnare una stella
        let starPath = createStarPath(center: point, radius: 20)
        
        // Converti il path in PKDrawing
        let ink = PKInk(.pen, color: .red)
        let tool = PKInkingTool(ink: ink, width: 3.0)
        
        
        // Crea strokes dal path
        let strokes = createStrokesFromPath(starPath, tool: tool)
        
        // Aggiungi al disegno esistente
        var newDrawing = self.drawing
        newDrawing.strokes.append(contentsOf: strokes)
        self.drawing = newDrawing
        
    }
    
    private func createStarPath(center: CGPoint, radius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        let points = 5
        let angleIncrement = (2 * CGFloat.pi) / CGFloat(points * 2)
        
        for i in 0..<(points * 2) {
            let angle = CGFloat(i) * angleIncrement - CGFloat.pi / 2
            let currentRadius = i % 2 == 0 ? radius : radius * 0.5
            let x = center.x + cos(angle) * currentRadius
            let y = center.y + sin(angle) * currentRadius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.close()
        return path
    }
    
    private func createStrokesFromPath(_ path: UIBezierPath, tool: PKInkingTool) -> [PKStroke] {
        // Implementazione semplificata - converte il path in punti per PKStroke
        var points: [PKStrokePoint] = []
        
        /*
        // Questo è un esempio semplificato
        // In realtà dovresti campionare il path più accuratamente
        let pathLength = path.length // Estensione necessaria per UIBezierPath
        let sampleCount = Int(pathLength / 2.0) // Un punto ogni 2 punti
        
        for i in 0..<sampleCount {
            let t = CGFloat(i) / CGFloat(sampleCount - 1)
            let point = path.point(at: t) // Estensione necessaria
            
            let strokePoint = PKStrokePoint(
                location: point,
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: tool.width, height: tool.width),
                opacity: 1.0,
                force: 1.0,
                azimuth: 0.0,
                altitude: CGFloat.pi / 2
            )
            points.append(strokePoint)
        }
        
        let path = PKStrokePath(controlPoints: points, creationDate: Date())
        return [PKStroke(ink: tool.ink, path: path)]
         */
        return []
    }
}

