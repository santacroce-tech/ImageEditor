import PencilKit
import SwiftUI

// iOS 18+
@available(iOS 18.0, *)
class StarStampTool: PKTool {
/*
    // L'inizializzatore rimane invariato
    init() {
        super.init(
            identifier: "com.example.pkeditor.starstamp",
            shape: .image(Image(systemName: "star.fill"))
        )
    }

    // Anche drawingBegan rimane invariato
    override func drawingBegan(point: PKToolPoint, on canvasView: PKCanvasView) {
        // Non facciamo nulla all'inizio del tocco
    }

    // --- METODO CORRETTO ---
    // Questo metodo viene chiamato quando il tocco finisce.
    override func drawingEnded(point: PKToolPoint, on canvasView: PKCanvasView) {
        // ACCESSO CORRETTO:
        // Accediamo al renderer direttamente dal parametro 'canvasView' che ci viene fornito qui.
        if let renderer = canvasView.renderer as? StarStampRenderer {
            // Diciamo al renderer di aggiungere una stella
            renderer.addStar(at: point.location)
            
            // Chiediamo al canvas di ridisegnare l'area interessata
            let dirtyRect = CGRect(origin: point.location, size: .zero).insetBy(dx: -25, dy: -25)
            canvasView.setNeedsDisplay(in: dirtyRect)
        }
    }
 */
}

// Il protocollo rimane invariato
@available(iOS 18.0, *)
protocol StarStampRenderer {
    func addStar(at point: CGPoint)
}
