import Foundation
import PencilKit
import CoreText // CoreText è necessario per questa logica

struct FontStrokeConverter {
    
    
    static func createStrokes(fromText text: String, font: UIFont, at center: CGPoint, color: UIColor, width: CGFloat, scale: CGFloat) -> [PKStroke] {
        
        var finalStrokes: [PKStroke] = []
        let ink = PKInk(.pen, color: color)
        
        // --- Passaggio A: Ottieni i tracciati e le posizioni per ogni carattere ---
        let attributedString = NSAttributedString(string: text, attributes: [.font: font])
        let line = CTLineCreateWithAttributedString(attributedString)
        let lineBounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        guard let runs = CTLineGetGlyphRuns(line) as? [CTRun] else { return [] }

        for run in runs {
            guard let runFont = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName]  else { continue }
            let glyphCount = CTRunGetGlyphCount(run)
            var glyphs = [CGGlyph](repeating: .init(), count: glyphCount)
            var positions = [CGPoint](repeating: .zero, count: glyphCount)
            CTRunGetGlyphs(run, CFRangeMake(0, glyphCount), &glyphs)
            CTRunGetPositions(run, CFRangeMake(0, glyphCount), &positions)
            
            // Itera su ogni singolo carattere
            for i in 0..<glyphCount {
                guard let letterPath = CTFontCreatePathForGlyph(runFont as! CTFont, glyphs[i], nil) else { continue }
                
                // --- Passaggio B: Calcola la trasformazione per questo singolo carattere ---
                
                // La posizione del carattere fornita da CoreText
                let letterPosition = positions[i]
                
                // Iniziamo con la trasformazione che posiziona il carattere all'interno della parola
                var transform = CGAffineTransform(translationX: letterPosition.x, y: letterPosition.y)
                
                // Invertiamo l'asse Y per allinearci a UIKit
                transform = transform.concatenating(CGAffineTransform(scaleX: 1.0, y: -1.0))

                // Applichiamo questa prima trasformazione al path del carattere
                guard let orientedPath = letterPath.copy(using: &transform) else { continue }

                // Ora calcoliamo una seconda trasformazione per posizionare l'INTERA PAROLA
                // al centro del tocco e scalarla.
                var groupTransform = CGAffineTransform.identity
                groupTransform = groupTransform.translatedBy(x: center.x - lineBounds.midX * scale,
                                                             y: center.y + lineBounds.midY * scale) // Usiamo + midY perché abbiamo già flippato
                groupTransform = groupTransform.scaledBy(x: scale, y: scale)
                
                // Applichiamo la trasformazione del gruppo al path del carattere già orientato
                guard let finalPath = orientedPath.copy(using: &groupTransform) else { continue }

                // --- Passaggio C: Converti il path finale in PKStroke(s) ---
                let subpaths = getSubpaths(from: finalPath)
                for pointArray in subpaths {
                    guard !pointArray.isEmpty else { continue }
                    
                    var strokePoints: [PKStrokePoint] = []
                    for (j, point) in pointArray.enumerated() {
                        strokePoints.append(PKStrokePoint(location: point, timeOffset: TimeInterval(j) * 0.01, size: CGSize(width: width, height: width), opacity: 1, force: 1, azimuth: 0, altitude: .pi / 2))
                    }

                    let strokePath = PKStrokePath(controlPoints: strokePoints, creationDate: Date())
                    let stroke = PKStroke(ink: ink, path: strokePath)
                    finalStrokes.append(stroke)
                }
            }
        }
        return finalStrokes
    }
    
    private static func getPoints(from path: CGPath) -> [CGPoint] {
        let scribe = PathScribe()
        let scribePointer = Unmanaged.passUnretained(scribe).toOpaque()
        path.apply(info: scribePointer, function: pathElementApplier)
        return scribe.points
    }
    /*
    /// Crea un array di PKStroke, uno per ogni carattere del testo, con alta precisione.
    static func createStrokes(fromText text: String, font: UIFont, at center: CGPoint, color: UIColor, width: CGFloat, scale: CGFloat) -> [PKStroke] {
        
        var finalStrokes: [PKStroke] = []
        let ink = PKInk(.pen, color: color)
        
        // --- Passaggio A: Ottieni i dati di layout per l'intera linea di testo ---
        let attributedString = NSAttributedString(string: text, attributes: [.font: font])
        let line = CTLineCreateWithAttributedString(attributedString)
        guard let runs = CTLineGetGlyphRuns(line) as? [CTRun] else { return [] }

        // Calcoliamo i limiti dell'intera parola per poterla centrare correttamente
        let lineBounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        
        for run in runs {
            guard let runFont = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName]  else { continue }
            let glyphCount = CTRunGetGlyphCount(run)
            
            var glyphs = [CGGlyph](repeating: .init(), count: glyphCount)
            CTRunGetGlyphs(run, CFRangeMake(0, glyphCount), &glyphs)
            
            var positions = [CGPoint](repeating: .zero, count: glyphCount)
            CTRunGetPositions(run, CFRangeMake(0, glyphCount), &positions)
            
            // --- Passaggio B: Itera su ogni singolo carattere (glifo) ---
            for i in 0..<glyphCount {
                // 1. Ottieni il path per UN SOLO carattere
                guard let letterPath = CTFontCreatePathForGlyph(runFont as! CTFont, glyphs[i], nil) else { continue }
                
                // 2. Calcola la trasformazione per QUESTO carattere
                //    che lo posiziona, lo ribalta, lo scala e lo centra sulla tela.
                let letterPosition = positions[i]
                var transform = CGAffineTransform.identity
                
                // Sposta alla posizione finale del tocco
                transform = transform.translatedBy(x: center.x, y: center.y)
                // Scala
                transform = transform.scaledBy(x: scale, y: scale)
                // Ribalta verticalmente per correggere il sistema di coordinate
                transform = transform.scaledBy(x: 1.0, y: -1.0)
                // Sposta alla posizione relativa all'interno della parola
                transform = transform.translatedBy(x: letterPosition.x - lineBounds.midX, y: -letterPosition.y - lineBounds.midY)
                
                guard let transformedPath = letterPath.copy(using: &transform) else { continue }
                
                // 3. Converti il path di questo singolo carattere in uno o più PKStroke
                //    usando la nostra logica di subpath e tassellazione.
                let subpaths = getSubpaths(from: transformedPath)
                for pointArray in subpaths {
                    guard !pointArray.isEmpty else { continue }
                    
                    var strokePoints: [PKStrokePoint] = []
                    for (j, point) in pointArray.enumerated() {
                        strokePoints.append(PKStrokePoint(
                            location: point, timeOffset: TimeInterval(j) * 0.01, size: CGSize(width: width, height: width),
                            opacity: 1, force: 1, azimuth: 0, altitude: .pi / 2
                        ))
                    }

                    let strokePath = PKStrokePath(controlPoints: strokePoints, creationDate: Date())
                    let stroke = PKStroke(ink: ink, path: strokePath)
                    finalStrokes.append(stroke)
                }
            }
        }
        return finalStrokes
    }
*/
    // MARK: - Logica di Conversione da Path a Punti

    /// Estrae i sotto-tracciati da un CGPath in modo sicuro.
    private static func getSubpaths(from path: CGPath) -> [[CGPoint]] {
        let scribe = PathScribe()
        let scribePointer = Unmanaged.passUnretained(scribe).toOpaque()
        path.apply(info: scribePointer, function: pathElementApplier)
        
        if !scribe.currentSubpathPoints.isEmpty {
            scribe.allSubpaths.append(scribe.currentSubpathPoints)
        }
        
        return scribe.allSubpaths
    }

    /// La funzione C-style che ora invoca la logica di tassellazione.
    private static let pathElementApplier: @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CGPathElement>) -> Void = { info, elementPtr in
        guard let scribePointer = info else { return }
        let scribe = Unmanaged<PathScribe>.fromOpaque(scribePointer).takeUnretainedValue()
        let element = elementPtr.pointee
        
        switch element.type {
        case .moveToPoint:
            if !scribe.currentSubpathPoints.isEmpty {
                scribe.allSubpaths.append(scribe.currentSubpathPoints)
            }
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
            TessellateStroke.tessellateQuadCurve(from: scribe.lastPoint, control: control, to: end, scribe: scribe)
            scribe.lastPoint = end

        case .addCurveToPoint:
            let control1 = element.points[0]
            let control2 = element.points[1]
            let end = element.points[2]
            TessellateStroke.tessellateCubicCurve(from: scribe.lastPoint, control1: control1, control2: control2, to: end, scribe: scribe)
            scribe.lastPoint = end

        case .closeSubpath:
            if let firstPoint = scribe.currentSubpathPoints.first {
                scribe.currentSubpathPoints.append(firstPoint)
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
