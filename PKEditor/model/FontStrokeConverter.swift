import Foundation
import PencilKit
import CoreText // CoreText è necessario per questa logica

struct FontStrokeConverter {
    static func createStrokes(fromText text: String, font: UIFont, at center: CGPoint, color: UIColor, width: CGFloat, scale: CGFloat) -> [PKStroke] {
        
        // --- Passaggio A: Converte l'intera stringa di testo in un unico CGPath ---
        // Questo ci serve per calcolare le dimensioni totali e il centro.
        let letters = CGMutablePath()
        let attributedString = NSAttributedString(string: text, attributes: [.font: font])
        let line = CTLineCreateWithAttributedString(attributedString)
        guard let runs = CTLineGetGlyphRuns(line) as? [CTRun] else { return [] }

        for run in runs {
            guard let runFont = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName]  else { continue }
            let glyphCount = CTRunGetGlyphCount(run)
            var glyphs = [CGGlyph](repeating: .init(), count: glyphCount)
            var positions = [CGPoint](repeating: .zero, count: glyphCount)
            CTRunGetGlyphs(run, CFRangeMake(0, glyphCount), &glyphs)
            CTRunGetPositions(run, CFRangeMake(0, glyphCount), &positions)
            
            for i in 0..<glyphCount {
                if let letterPath = CTFontCreatePathForGlyph(runFont as! CTFont, glyphs[i], nil) {
                    let transform = CGAffineTransform(translationX: positions[i].x, y: positions[i].y)
                    letters.addPath(letterPath, transform: transform)
                }
            }
        }
        
        // --- Passaggio B: Calcola e Applica la Trasformazione Finale (LOGICA NUOVA E CORRETTA) ---
         
         let pathBounds = letters.boundingBoxOfPath
         
         // 1. Trasformazione per centrare il path originale sull'origine (0,0)
         let centerTransform = CGAffineTransform(translationX: -pathBounds.midX, y: -pathBounds.midY)
         
         // 2. Trasformazione per ribaltare verticalmente il path (corregge le coordinate di Core Text)
         let flipTransform = CGAffineTransform(scaleX: 1.0, y: -1.0)
         
         // 3. Trasformazione per scalare
         let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
         
         // 4. Trasformazione per spostare il path alla posizione finale del tocco
         let finalTranslateTransform = CGAffineTransform(translationX: center.x, y: center.y)

         // 5. Concateniamo le trasformazioni nell'ordine corretto.
         //    L'ordine di concatenazione è importante: la prima trasformazione da applicare va più a destra.
         var combinedTransform = centerTransform
             .concatenating(flipTransform)
             .concatenating(scaleTransform)
             .concatenating(finalTranslateTransform)

         // Applichiamo la singola trasformazione composita al path originale
         guard let transformedPath = letters.copy(using: &combinedTransform) else { return [] }
         
         // --- Passaggio C: Converte il Path finale in PKStroke(s) (invariato) ---
         
        let subpaths = TessellateStroke.getSubpaths(from: transformedPath)
         var finalStrokes: [PKStroke] = []
         let ink = PKInk(.pen, color: color)

         for pointArray in subpaths {
             if let newStroke = TessellateStroke.createStrokeFromSubpath(points: pointArray, ink: ink, width: width) {
                 finalStrokes.append(newStroke)
             }
         }
         
         return finalStrokes
   
    }
}
