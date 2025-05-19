import UIKit
import PencilKit


class ImageEditorViewController: UIViewController, PKCanvasViewDelegate, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {

    let canvasView = PKCanvasView()
    let layerManager = LayerManager()
    let layerContainerView = UIView()
    let toolbar = UIStackView()
    var selectedLayer: EditorLayer?
    var isDrawingMode = false
    var toolPicker: PKToolPicker?
    let scrollView = UIScrollView()
    let canvasContentView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.bringSubviewToFront(toolbar)
        setupCanvasEnvironment()
        setupLayerContainer()
        setupToolbar()
    }

    private func setupCanvasEnvironment() {
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.minimumZoomScale = 0.2
        scrollView.maximumZoomScale = 3.0
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)

        // Use screen size as canvas size
        let canvasSize = view.bounds.size
        canvasContentView.frame = CGRect(origin: .zero, size: canvasSize)
        scrollView.contentSize = canvasSize
        scrollView.contentOffset = .zero
        scrollView.addSubview(canvasContentView)

        canvasView.frame = canvasContentView.bounds
        canvasView.drawingPolicy = .anyInput
        canvasView.isOpaque = false
        canvasView.backgroundColor = .clear
        canvasView.delegate = self
        canvasView.isUserInteractionEnabled = false
        canvasContentView.addSubview(canvasView)

        layerContainerView.frame = canvasContentView.bounds
        layerContainerView.backgroundColor = .clear
        canvasContentView.addSubview(layerContainerView)

        view.bringSubviewToFront(toolbar)
    }
 
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return canvasContentView
    }
    
    private func setupCanvas() {
        canvasView.delegate = self
        canvasView.drawingPolicy = .anyInput
        canvasView.frame = view.bounds
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        canvasView.isUserInteractionEnabled = false // <-- initially off
        view.addSubview(canvasView)
        view.bringSubviewToFront(canvasView)
    }

    private func setupLayerContainer() {
        layerContainerView.frame = view.bounds
        layerContainerView.backgroundColor = .clear
        layerContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(layerContainerView)
    }

    private func setupToolbar() {
        let scrollableToolbar = UIScrollView()
        scrollableToolbar.translatesAutoresizingMaskIntoConstraints = false
        scrollableToolbar.showsHorizontalScrollIndicator = false
        scrollableToolbar.addSubview(toolbar)

        // Set constraints for toolbar within scrollableToolbar
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: scrollableToolbar.topAnchor),
            toolbar.bottomAnchor.constraint(equalTo: scrollableToolbar.bottomAnchor),
            toolbar.leadingAnchor.constraint(equalTo: scrollableToolbar.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: scrollableToolbar.trailingAnchor),
            toolbar.heightAnchor.constraint(equalTo: scrollableToolbar.heightAnchor)
        ])

        view.addSubview(scrollableToolbar)

        // Set constraints for scrollableToolbar
        NSLayoutConstraint.activate([
            scrollableToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scrollableToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollableToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollableToolbar.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        let imageButton = makeToolbarButton(systemName: "photo", action: #selector(addImageLayer))
        let textButton = makeToolbarButton(systemName: "textformat", action: #selector(addTextLayer))
        let drawButton = makeToolbarButton(systemName: "pencil.tip", action: #selector(toggleDrawMode))
        let layersButton = makeToolbarButton(systemName: "square.stack", action: #selector(showLayerList))
        let cropButton = makeToolbarButton(systemName: "crop", action: #selector(startCropMode))
        let flattenButton = makeToolbarButton(systemName: "rectangle.stack.fill.badge.minus", action: #selector(flattenAllLayers))
        let saveButton = makeToolbarButton(systemName: "square.and.arrow.down", action: #selector(saveFlattenedImage))
        let resetButton = makeToolbarButton(systemName: "arrow.counterclockwise", action: #selector(resetZoomAndPosition))
        let zoomInButton = makeToolbarButton(systemName: "plus.magnifyingglass", action: #selector(zoomIn))
        let zoomOutButton = makeToolbarButton(systemName: "minus.magnifyingglass", action: #selector(zoomOut))
        let eraserButton = makeToolbarButton(systemName: "eraser", action: #selector(enableEraserTool))
        let undoButton = makeToolbarButton(systemName: "arrow.uturn.left", action: #selector(undoAction))
        let redoButton = makeToolbarButton(systemName: "arrow.uturn.right", action: #selector(redoAction))
        
        toolbar.addArrangedSubview(undoButton)
        toolbar.addArrangedSubview(redoButton)
        toolbar.addArrangedSubview(eraserButton)
        toolbar.addArrangedSubview(zoomInButton)
        toolbar.addArrangedSubview(zoomOutButton)
        toolbar.addArrangedSubview(resetButton)
        toolbar.addArrangedSubview(imageButton)
        toolbar.addArrangedSubview(textButton)
        toolbar.addArrangedSubview(drawButton)
        toolbar.addArrangedSubview(layersButton)
        toolbar.addArrangedSubview(cropButton)
        toolbar.addArrangedSubview(flattenButton)
        toolbar.addArrangedSubview(saveButton)

    }
    
    @objc func undoAction() {
        canvasView.undoManager?.undo()
    }

    @objc func redoAction() {
        canvasView.undoManager?.redo()
    }
    
    @objc func enableEraserTool() {
        let eraser = PKEraserTool(.vector)
        canvasView.tool = eraser
    }
    
    @objc func zoomIn() {
        let newZoomScale = min(scrollView.zoomScale * 1.2, scrollView.maximumZoomScale)
        scrollView.setZoomScale(newZoomScale, animated: true)
        showZoomLevelToast()
    }

    @objc func zoomOut() {
        let newZoomScale = max(scrollView.zoomScale / 1.2, scrollView.minimumZoomScale)
        scrollView.setZoomScale(newZoomScale, animated: true)
        showZoomLevelToast()
    }

    func showZoomLevelToast() {
        let zoomPercentage = Int(scrollView.zoomScale * 100)
        showToast(message: "Zoom: \(zoomPercentage)%")
    }
    
    @objc func resetZoomAndPosition() {
        scrollView.setZoomScale(1.0, animated: true)

        // Center the canvas content
        let offsetX = (scrollView.contentSize.width - scrollView.bounds.width) / 2
        let offsetY = (scrollView.contentSize.height - scrollView.bounds.height) / 2
        let centeredOffset = CGPoint(x: max(offsetX, 0), y: max(offsetY, 0))

        scrollView.setContentOffset(centeredOffset, animated: true)

        showToast(message: "Canvas reset")
    }

    
    private func makeToolbarButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    @objc func saveFlattenedImage() {
        let size = view.bounds.size
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)

        for layer in layerManager.layers {
            layer.view.drawHierarchy(in: layer.view.frame, afterScreenUpdates: true)
        }

        let drawingBounds = canvasView.drawing.bounds.integral
        let canvasImage = canvasView.drawing.image(from: drawingBounds, scale: 1.0)
        canvasImage.draw(in: drawingBounds)
        
        guard let finalImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return
        }
        UIGraphicsEndImageContext()

        UIImageWriteToSavedPhotosAlbum(finalImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let alert = UIAlertController(
            title: error == nil ? "Saved!" : "Error",
            message: error == nil ? "Image saved to Photos." : error?.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc func flattenAllLayers() {
        let size = view.bounds.size
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)

        for layer in layerManager.layers {
            layer.view.drawHierarchy(in: layer.view.frame, afterScreenUpdates: true)
        }

        let canvasImage = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
        canvasImage.draw(in: canvasView.frame)

        guard let finalImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return
        }
        UIGraphicsEndImageContext()

        // Clear all layers
        for layer in layerManager.layers {
            layer.view.removeFromSuperview()
        }
        layerManager.clear()
        canvasView.drawing = PKDrawing()

        // Add flattened image back as one layer
        let imageView = UIImageView(image: finalImage)
        imageView.frame = view.bounds
        imageView.isUserInteractionEnabled = true
        addGestures(to: imageView)

        let layer = EditorLayer(view: imageView, zIndex: 0)
        layerManager.addLayer(layer, to: layerContainerView)
        
        showToast(message: "Canvas flattened into one layer")
    }
    @objc func toggleDrawMode(_ sender: Any? = nil) {
        view.bringSubviewToFront(canvasView)
        if let doneButton = view.viewWithTag(888) {
            view.bringSubviewToFront(doneButton)
        }

        isDrawingMode.toggle()
        canvasView.isUserInteractionEnabled = isDrawingMode
        layerContainerView.isUserInteractionEnabled = !isDrawingMode
        scrollView.isScrollEnabled = !isDrawingMode // ✅ Disable scrolling while drawing

        if isDrawingMode {
            addFloatingDoneButton()

            if let _ = view.window, toolPicker == nil {
                toolPicker = PKToolPicker()
                toolPicker?.setVisible(true, forFirstResponder: canvasView)
                toolPicker?.addObserver(canvasView)
            }

            toolPicker?.setVisible(true, forFirstResponder: canvasView)
            canvasView.becomeFirstResponder()
        } else {
            removeFloatingDoneButton()
            canvasView.resignFirstResponder()
            toolPicker?.setVisible(false, forFirstResponder: canvasView)
            captureDrawingToLayer()
            canvasView.drawing = PKDrawing()
        }
    }
    
    private func captureDrawingToLayer() {
        let drawingBounds = canvasView.drawing.bounds.integral
        guard !drawingBounds.isEmpty else { return }

        let image = canvasView.drawing.image(from: drawingBounds, scale: 1.0)
        let imageView = UIImageView(image: image)
        imageView.frame = drawingBounds
        imageView.isUserInteractionEnabled = true
        addGestures(to: imageView)

        let layer = EditorLayer(view: imageView, zIndex: layerManager.layers.count)
        layerManager.addLayer(layer, to: layerContainerView)

        autoFocusOnDrawing(to: imageView)
    }

    private func autoFocusOnDrawing(to targetView: UIView) {
        let targetRect = targetView.frame.insetBy(dx: -100, dy: -100) // extra padding
        scrollView.zoom(to: targetRect, animated: true)
        
        let zoomLevel = Int(scrollView.zoomScale * 100)
        showToast(message: "Zoomed to \(zoomLevel)%")
    }

    
    @objc func showLayerList() {
        let listVC = LayerListViewController()
        listVC.layers = layerManager.layers.reversed() // top-to-bottom
        listVC.onSelect = { [weak self] layer in
            guard let self = self else { return }
            self.bringLayerToFront(layer)
        }
        listVC.onDelete = { [weak self] layer in
            guard let self = self else { return }
            self.layerManager.removeLayer(layer.id)
        }
        listVC.onReorder = { [weak self] newOrder in
            guard let self = self else { return }
            self.layerManager.reorderLayers(newOrder.reversed())
        }

        listVC.modalPresentationStyle = .pageSheet
        if let sheet = listVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        present(listVC, animated: true)
    }
    
    private func bringLayerToFront(_ layer: EditorLayer) {
        guard layerManager.layers.contains(where: { $0.id == layer.id }) else { return }
        layerManager.bringToFront(layer.id)
    }

    
    @objc func addImageLayer() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        present(picker, animated: true)
    }

    @objc func addTextLayer() {
        let label = UILabel()
        label.text = "New Text"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .black
        label.sizeToFit()
        label.center = CGPoint(x: 200, y: 200)
        label.isUserInteractionEnabled = true
        addGestures(to: label)

        let layer = EditorLayer(view: label, zIndex: layerManager.layers.count)
        layerManager.addLayer(layer, to: layerContainerView)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else { return }

        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(x: 100, y: 100, width: 200, height: 200)
        imageView.isUserInteractionEnabled = true
        addGestures(to: imageView)

        let layer = EditorLayer(view: imageView, zIndex: layerManager.layers.count)
        layerManager.addLayer(layer, to: layerContainerView)
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        let translation = gesture.translation(in: layerContainerView)
        view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
        gesture.setTranslation(.zero, in: layerContainerView)
    }

    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }
        view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
        gesture.scale = 1
    }

    @objc func handleRotate(_ gesture: UIRotationGestureRecognizer) {
        guard let view = gesture.view else { return }
        view.transform = view.transform.rotated(by: gesture.rotation)
        gesture.rotation = 0
    }

    @objc func handleTextTap(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel else { return }

        let alert = UIAlertController(title: "Edit Text", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = label.text
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let newText = alert.textFields?.first?.text {
                label.text = newText
                label.sizeToFit()
            }
        })
        
        selectedLayer = layerManager.layers.first { $0.view === label } // for text
        
        present(alert, animated: true)
    }

    private func addGestures(to view: UIView) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate(_:)))

        pan.delegate = self
        pinch.delegate = self
        rotation.delegate = self

        view.addGestureRecognizer(pan)
        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(rotation)

        if view is UILabel {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTextTap(_:)))
            tap.delegate = self
            view.addGestureRecognizer(tap)
        }
        
        if view is UIImageView {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)))
            tap.delegate = self
            view.addGestureRecognizer(tap)
        }

    }

    @objc func handleImageTap(_ gesture: UITapGestureRecognizer) {
        guard let imageView = gesture.view as? UIImageView else { return }
        presentCropOverlay(for: imageView)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func presentCropOverlay(for imageView: UIImageView) {
        let overlay = CropOverlayView(frame: view.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let cropButton = UIButton(type: .system)
        cropButton.setTitle("Crop", for: .normal)
        cropButton.tintColor = .white
        cropButton.backgroundColor = .black
        cropButton.layer.cornerRadius = 8
        cropButton.addTarget(nil, action: #selector(applyCrop(_:)), for: .touchUpInside)
        cropButton.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(cropButton)

        NSLayoutConstraint.activate([
            cropButton.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -40),
            cropButton.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            cropButton.widthAnchor.constraint(equalToConstant: 100),
            cropButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.tintColor = .white
        cancelButton.backgroundColor = .systemRed
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelCrop), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            cancelButton.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -40),
            cancelButton.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 20),
            cancelButton.widthAnchor.constraint(equalToConstant: 100),
            cancelButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        selectedLayer = layerManager.layers.first { $0.view === imageView } // for image
        
        overlay.tag = 999
        overlay.accessibilityHint = "crop:\(imageView.hash)"
        view.addSubview(overlay)
    }
    
    @objc func cancelCrop() {
        view.viewWithTag(999)?.removeFromSuperview()
    }
    
    @objc func applyCrop(_ sender: UIButton) {
        guard let overlay = view.viewWithTag(999) as? CropOverlayView else { return }
        overlay.removeFromSuperview()

        // Get the matching imageView from hash
        guard let hint = overlay.accessibilityHint,
              let hashStr = hint.split(separator: ":").last,
              let imageView = layerManager.layers
                .compactMap({ $0.view as? UIImageView })
                .first(where: { "\($0.hash)" == hashStr }) else { return }

        let cropRect = overlay.cropRect
        UIGraphicsBeginImageContextWithOptions(cropRect.size, false, 0)
        imageView.image?.draw(at: CGPoint(x: -cropRect.origin.x, y: -cropRect.origin.y))
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        imageView.image = croppedImage
        imageView.frame = CGRect(origin: cropRect.origin, size: cropRect.size)
    }

    @objc func startCropMode() {
        guard let selected = selectedLayer,
              let imageView = selected.view as? UIImageView else {
            print("No image layer selected")
            return
        }

        presentCropOverlay(for: imageView)
    }

    private func addFloatingDoneButton() {
        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.backgroundColor = .black
        doneButton.layer.cornerRadius = 10
        doneButton.tag = 888
        doneButton.addTarget(self, action: #selector(toggleDrawMode(_:)), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(doneButton)

        NSLayoutConstraint.activate([
            doneButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.widthAnchor.constraint(equalToConstant: 80),
            doneButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func removeFloatingDoneButton() {
        view.viewWithTag(888)?.removeFromSuperview()
    }
    
    private func showToast(message: String, duration: Double = 2.0) {
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.font = .systemFont(ofSize: 14, weight: .medium)
        toastLabel.textColor = .white
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastLabel.textAlignment = .center
        toastLabel.numberOfLines = 0
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 10
        toastLabel.layer.masksToBounds = true
        toastLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(toastLabel)

        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            toastLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 250),
            toastLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])

        UIView.animate(withDuration: 0.3, animations: {
            toastLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: duration, options: [], animations: {
                toastLabel.alpha = 0.0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
    
  


}

