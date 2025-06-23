//
//  MyCanvasView.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//

import SwiftUI
import PencilKit
import SVGKit



struct LayerCanvasView: UIViewRepresentable {
   
    @Binding var activeCanvasId: Int
    //@Binding var toolPickerState: ToolPickerState
    @Binding var sharedOffset: CGPoint
    @State private var localToolPicker: PKToolPicker
    var model:LayerCanvasModel
    let accessoryButton = UIBarButtonItem(image: UIImage(systemName: "signature"), style: .plain, target: nil, action: nil)
    @ObservedObject var editor = EditorModel.shared
    //toolPickerState: Binding<ToolPickerState>,
    init(model:LayerCanvasModel, activeCanvasId: Binding<Int>,  sharedOffset: Binding<CGPoint>) {
        self.model = model
        print("cpu initcpu")
       //self.currentCanvasId = currentCanvasId
        _activeCanvasId = activeCanvasId
        //_toolPickerState = toolPickerState
        _sharedOffset = sharedOffset
        // Initialize the local PKToolPicker here (no 'for: window' needed)
        
        /*
         var config = PKToolPickerCustomItem.Configuration(identifier: "lr.PKEditor", name: "star")
         
         // Provide a custom image for the custom tool item.
         config.imageProvider = { toolItem in
         guard let toolImage = UIImage(named: config.name) else {
         return UIImage()
         }
         return toolImage
         }
         
         
         // Configure additional appearance options for the custom tool item.
         config.allowsColorSelection = true
         config.defaultColor = .red
         config.defaultWidth = 45.0
         config.widthVariants = [28: UIImage(named: config.name)!,45.0: UIImage(named: config.name)!,90.0: UIImage(named: config.name)!]
         
         
         // Create a custom tool item using the configuration.
         let customItem = PKToolPickerCustomItem(configuration: config)
         */
        
        // Create a picker with the custom tool item and a system ruler tool.
        //let items = PKToolPicker().toolItems //PKToolPickerRulerItem()
        //let picker = PKToolPicker(toolItems: items)
        
        //self.animalStampWrapper = AnimalStampWrapper()
        
        /*let toolPickerRed = UIColor(red: 252 / 255, green: 49 / 255, blue: 66 / 255, alpha: 1)
         let penWidth = PKInkingTool.InkType.pen.defaultWidth
         let secondPen = PKToolPickerInkingItem(type: .pen,
         color: toolPickerRed,
         width: penWidth,
         identifier: "com.example.apple-samplecode.second-pen")
         */
        
        //_localToolPicker = State(initialValue: PKToolPicker())
        
        if let picker = EditorModel.shared.toolPicker {
            _localToolPicker = State(initialValue: picker)
        }else{
            let toolItems = [EditorModel.shared.shapeStampWrapper.toolItem] +
            [EditorModel.shared.textStampWrapper.toolItem] +
            PKToolPicker().toolItems
            
            let picker = PKToolPicker(toolItems: toolItems)
            EditorModel.shared.toolPicker = picker
            _localToolPicker = State(initialValue: picker)
        }
        if EditorModel.shared.mainMenu == nil {
            EditorModel.shared.createPopupMenu()
        }
        
    }
    
    func makeUIView(context: Context) -> PKCanvasView {
        
        print("cpu makeUIView")
     
        let canvasView = PKCanvasView()
        canvasView.drawing = model.drawing
        //canvasView.drawingPolicy = .anyInput
        canvasView.drawingPolicy = model.drawingPolicy
        canvasView.isOpaque = false
        canvasView.backgroundColor = .clear
        canvasView.delegate = context.coordinator
        canvasView.contentSize = EditorModel.shared.contentSize //CGSize(width: 2000, height: 2000)
        
        canvasView.minimumZoomScale = EditorModel.shared.minimumZoomScale
        canvasView.maximumZoomScale = EditorModel.shared.maximumZoomScale
        model.canvas = canvasView
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Su iPad, questa policy permetterà di disegnare con la Pencil e scorrere con il dito.
            canvasView.drawingPolicy = .pencilOnly
            print("POLICY IMPOSTATA: .pencilOnly (iPad)")
        } else {
            // Su iPhone, questa policy permetterà di disegnare con il dito.
            canvasView.drawingPolicy = .anyInput
            print("POLICY IMPOSTATA: .anyInput (iPhone)")
        }
        
        // Add observers to this specific localToolPicker instance
        localToolPicker.addObserver(canvasView)
        localToolPicker.addObserver(context.coordinator)
        /*localToolPicker.accessoryItem = UIBarButtonItem(image: UIImage(systemName: "signature"), primaryAction: UIAction(handler: {  _ in //[self]
         EditorModel.shared.isShowingAccessorySheet = true
         }))*/
        if let mainMenu = EditorModel.shared.mainMenu {
            let menuButton = UIBarButtonItem(image: UIImage(systemName: "command"), menu: mainMenu)
            // Assegniamo il bottone come accessoryItem del picker
            localToolPicker.accessoryItem = menuButton
        }
        //var overrideUserInterfaceStyle: UIUserInterfaceStyle
        /*localToolPicker.showsDrawingPolicyControls = true
         localToolPicker.stateAutosaveName = "com.example.swiftui-pencilkit-demo.localToolPickerState"
         */
        context.coordinator.setUpGestureRecognizers(on: canvasView)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Only set visible and become first responder if this is the active canvas on initial load
            let shouldBeActive = (model.currentCanvasId == activeCanvasId)
            if shouldBeActive  { //&& model.pickerVisibility
                self.localToolPicker.setVisible(true, forFirstResponder: canvasView)
                canvasView.becomeFirstResponder()
                // Restore state using this canvas's local tool picker
                //self.restoreToolPickerState(self.localToolPicker, from: self.toolPickerState, for: canvasView)
            } else {
                // Ensure it's hidden if not active initially
                //self.localToolPicker.setVisible(false, forFirstResponder: canvasView)
                //canvasView.resignFirstResponder()
            }
        }
        
        // --- AGGIUNGI QUESTO BLOCCO PER IL DEBUG ---
        /*  let debugView = UIView(frame: canvasView.bounds)
         debugView.backgroundColor = UIColor.systemPink.withAlphaComponent(0.3) // Sfondo colorato per vederla
         debugView.isUserInteractionEnabled = false
         debugView.autoresizingMask = [.flexibleWidth, .flexibleHeight] // Si adatta alla dimensione del canvas
         debugView.tag = 12345 // Un tag per poterla rimuovere dopo
         canvasView.addSubview(debugView)
         */
        //EditorModel.shared.registerCanvasView(canvasView, forLayerID: model.id)

        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        print("cpu updateUIView")
        if uiView.drawing != model.drawing {
            uiView.drawing = model.drawing
        }
        
        let shouldBeActive = (model.currentCanvasId == activeCanvasId)
        
        //if let _ = uiView.undoManager{
        //    EditorModel.shared.setActiveUndoManager(uiView.undoManager)
        //}
        if shouldBeActive { //&& model.pickerVisibility
            // This canvas should be active: make its local tool picker visible
            
            /*if EditorModel.shared.activeUndoManager !== uiView.undoManager {
                        EditorModel.shared.setActiveUndoManager(uiView.undoManager)
                    }*/
            
            DispatchQueue.main.async{
                localToolPicker.setVisible(true, forFirstResponder: uiView)
                uiView.becomeFirstResponder()
            }
            // Restore state using this canvas's local tool picker
            //restoreToolPickerState(localToolPicker, from: toolPickerState, for: uiView)
        } else {
            // This canvas is NOT active: hide its local tool picker
            localToolPicker.setVisible(false, forFirstResponder: uiView)
            uiView.resignFirstResponder() // Important: resign first responder
        }
        
        
        if !shouldBeActive {
            
            //&& sharedOffset != .zero
            // Usiamo `setContentOffset` senza animazione per un allineamento istantaneo.
            //DispatchQueue.main.async{
            if uiView.zoomScale != EditorModel.shared.zoomScale {
                // Applichiamo direttamente lo zoomScale. Non serve animazione.
                uiView.zoomScale = EditorModel.shared.zoomScale
            }
            if  uiView.contentOffset != sharedOffset {
                uiView.setContentOffset(sharedOffset, animated: false)
            }
            //}
        }
    }
    
    // New: dismantleUIView for cleanup when the UIView is removed from the hierarchy
    static func dismantleUIView(_ uiView: PKCanvasView, coordinator: Coordinator) {
        // Access the localToolPicker via the coordinator's parent (LayerCanvasView)
        // Ensure to remove observers specific to this PKToolPicker instance
        coordinator.parent.localToolPicker.removeObserver(uiView)
        coordinator.parent.localToolPicker.removeObserver(coordinator)
        // Also hide it, as it might have been the active one before being dismantled
        coordinator.parent.localToolPicker.setVisible(false, forFirstResponder: uiView)
        uiView.resignFirstResponder()
  
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func restoreToolPickerState(_ picker: PKToolPicker, from state: ToolPickerState, for canvas: PKCanvasView) {
        
        
        /*picker.isRulerActive = state.isRulerActive
         
         if let identifier = state.selectedToolIdentifier {
         if identifier.contains("ink") {
         canvas.tool = PKInkingTool(state.inkType, color: state.color, width: state.width)
         } else if identifier.contains("eraser") {
         canvas.tool = PKEraserTool(state.eraserType)
         } else if identifier.contains("lasso"){
         canvas.tool = PKLassoTool()
         }
         }*/
    }
    
    // All'interno di LayerCanvasView.swift
    
    
    class Coordinator: NSObject {
        var parent: LayerCanvasView
        
        // --- MODIFICA 1: Usa opzionali standard (?) invece di impliciti (!) ---
        var stampGestureRecognizer: StampGestureRecognizer?
        var stampHoverGestureRecognizer: UIHoverGestureRecognizer?
        private var hoverPreviewView: UIView?
        
        init(_ parent: LayerCanvasView) {
            self.parent = parent
            super.init()
        }
        
        
        
        
        @MainActor @objc func handleHover(_ sender: UIHoverGestureRecognizer) {
#if os(iOS)
            guard UIPencilInteraction.prefersHoverToolPreview else { return }
#endif
            
            guard let canvasView = sender.view as? PKCanvasView else { return }
            let point = sender.location(in: canvasView)
            let angleInRadians = sender.azimuthAngle(in: sender.view) - sender.rollAngle
            
            switch sender.state {
            case .changed:
                hoverPreviewView?.removeFromSuperview()
                hoverPreviewView = nil
                if let imageView = EditorModel.shared.shapeStampWrapper.stampImageView(for: point, angleInRadians: angleInRadians) {
                    imageView.alpha = 0.5
                    canvasView.addSubview(imageView)
                    hoverPreviewView = imageView
                } else {
                    hoverPreviewView = nil
                }
            default:
                hoverPreviewView?.removeFromSuperview()
                hoverPreviewView = nil
            }
        }
        
        
        
    }
}


extension LayerCanvasView.Coordinator {
    func setUpGestureRecognizers(on view: UIView) {
        stampGestureRecognizer = StampGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(stampGestureRecognizer!)
        
        // Aggiungi qui anche l'hover gesture recognizer se lo usi
    }
    
    @MainActor @objc func handleTap(_ sender: StampGestureRecognizer) {
        guard let canvasView = sender.view as? PKCanvasView else { return }
        
        let location = sender.location(in: canvasView)
        
        let stampWrapper = EditorModel.shared.shapeStampWrapper
        
        let stampToolIdentifier = EditorModel.shared.shapeStampWrapper.toolItem.identifier
      
        let textToolIdentifier = EditorModel.shared.textStampWrapper.toolItem.identifier
      
        // 2. Otteniamo l'identificatore dello strumento attualmente selezionato nel picker.
        let selectedIdentifier = EditorModel.shared.toolPicker!.selectedToolItemIdentifier
        
        // 3. Confrontiamo i due identificatori.
        let isTextToolSelected = (selectedIdentifier == textToolIdentifier)
        if isTextToolSelected {
            EditorModel.shared.showTextInput.toggle()
        }
        
        let isStampToolSelected = (selectedIdentifier == stampToolIdentifier)
        if isStampToolSelected {
            let selectedAttribute = stampWrapper.attributeViewController.attributeModel.selectedAttribute
            
            let svgName = "\(selectedAttribute.name).svg"
            let color = stampWrapper.toolItem.color
            let width = stampWrapper.toolItem.width
            let scale = stampWrapper.toolItem.width - 2.0
            
            print("Uso: SVG=\(svgName), Colore=\(color.description), Spessore=\(width)")
            
            
            let newStrokes = SVGStrokeConverter.createStrokes(fromSVGNamed: svgName, at: location, color: color, width: width, scale: scale)
            
            let drawing = PKDrawing(strokes: newStrokes)
            let newDrawing = canvasView.drawing.appending(drawing)
            EditorModel.shared.setNewDrawingUndoable(newDrawing,to:canvasView)
        }
  
        /*if let imageView = EditorModel.shared.animalStampWrapper.stampImageView(for: sender.location(in: canvasView), angleInRadians: sender.angleInRadians) {
         // Aggiungiamo l'immagine direttamente come subview della canvas
         canvasView.addSubview(imageView)
         //insertImageViewUndoable(newDrawing,to:canvasView)
         }*/
        
         //UIFont.systemFont(ofSize: 60)
         
        //let font = UIFont(name: "Helvetica-Light", size: 19)!
        //let font = UIFont(name: "Impact", size: 19)!
        //let font = UIFont(name: "Verdana", size: 19)!
         /*
         let newFontStrokes = FontStrokeConverter.createStrokes(fromText: "Hello TEXT!",font:font, at: location, color: color, width: 3, scale:scale)
         
         let drawing1 = PKDrawing(strokes: newFontStrokes)
         let newDrawing1 = canvasView.drawing.appending(drawing1)
         setNewDrawingUndoable(newDrawing1,to:canvasView)
        */
    }
    
    private func insertImageViewUndoable(_ imageView: UIImageView) {
        /*undoManager?.registerUndo(withTarget: self) {
         $0.removeImageViewUndoable(imageView)
         }*/
        //canvasView.addSubview(imageView)
    }
    
   
}


// MARK: - PencilKit Delegates
extension LayerCanvasView.Coordinator: PKCanvasViewDelegate, PKToolPickerObserver {
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
       // La logica è identica a quella per lo scroll.
       let isActive = parent.model.id == parent.activeCanvasId
       
       if isActive {
           // Se è la tela attiva, aggiorniamo lo zoom condiviso nel nostro modello.
           EditorModel.shared.zoomScale = scrollView.zoomScale
       }
   }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Controlliamo se questa è la tela attiva.
        // Vogliamo che solo la tela attiva "guidi" lo scorrimento di tutte le altre.
        let isActive = parent.model.id == parent.activeCanvasId
        
        if isActive {
            // Se è la tela attiva, aggiorniamo l'offset condiviso nel nostro modello.
            Task{
                EditorModel.shared.contentOffset = scrollView.contentOffset
            }
        }
    }
    
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        DispatchQueue.main.async {
            //let newDrawing = PKDrawing(strokes: canvasView.drawing.strokes)
            //self.parent.model.drawing = newDrawing
            //EditorModel.shared.objectWillChange.send()
            self.parent.model.drawing = canvasView.drawing
        }
    }
    
    func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            // Questo è il momento giusto per notificare al resto dell'app
            // che è avvenuta una modifica "permanente".
            // La nostra funzione di notifica globale è perfetta per questo.
            //EditorModel.shared.notifyLayerDidChange()
        //print("Tratto finalizzato. Notifica inviata per aggiornare i thumbnail.")
        }
    
    // Questo metodo viene chiamato OGNI VOLTA che cambi strumento.
    func toolPickerSelectedToolItemDidChange(_ toolPicker: PKToolPicker) {
        // Chiamiamo la nostra funzione di aggiornamento, passandole il picker attuale.
        updateGestureRecognizerEnablement(using: toolPicker)
    }
    
    // Questa è la funzione chiave, ora implementata correttamente.
    @MainActor func updateGestureRecognizerEnablement(using toolPicker: PKToolPicker) {
        
        // 1. Otteniamo l'identificatore del nostro strumento Timbro dal modello.
        //    Questo è l'identificatore "corretto" che stiamo cercando.
        let stampToolIdentifier = EditorModel.shared.shapeStampWrapper.toolItem.identifier
        let textToolIdentifier = EditorModel.shared.textStampWrapper.toolItem.identifier
      
        // 2. Otteniamo l'identificatore dello strumento attualmente selezionato nel picker.
        let selectedIdentifier = toolPicker.selectedToolItemIdentifier
        
        // 3. Confrontiamo i due identificatori.
        let isStampToolSelected = (selectedIdentifier == stampToolIdentifier)
        let isTextToolSelected = (selectedIdentifier == textToolIdentifier)
     
        // 4. Abilitiamo o disabilitiamo il nostro gesture recognizer di conseguenza.
        stampGestureRecognizer?.isEnabled = isStampToolSelected || isTextToolSelected
        DispatchQueue.main.async{
            if isTextToolSelected {
                EditorModel.shared.showTextInput = true
            }
            
        }
        // Aggiungiamo un print di debug per vedere cosa sta succedendo
        if isStampToolSelected {
            print("Strumento Timbro ATTIVATO. HandleTap ora funzionerà.")
        } else {
            print("Strumento Timbro DISATTIVATO. HandleTap è disabilitato.")
        }
    }
    
    // Lasciamo questo metodo vuoto per ora, ma è importante che ci sia.
    func toolPickerIsRulerActiveDidChange(_ toolPicker: PKToolPicker) {}
}

extension LayerCanvasView {
}
