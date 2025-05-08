import UIKit
import PencilKit

class ImageEditorViewController: UIViewController, PKCanvasViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {

    let canvasView = PKCanvasView()
    let layerManager = LayerManager()
    let layerContainerView = UIView()
    var selectedLayer: EditorLayer?
    var isDrawingMode = false
    var toolPicker: PKToolPicker?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupCanvas()
        setupLayerContainer()
        setupToolbar()
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
        let toolbar = UIStackView()
        toolbar.axis = .horizontal
        toolbar.spacing = 16
        toolbar.alignment = .center
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        let imageButton = UIButton(type: .system)
        imageButton.setTitle("Add Image", for: .normal)
        imageButton.addTarget(self, action: #selector(addImageLayer), for: .touchUpInside)

        let textButton = UIButton(type: .system)
        textButton.setTitle("Add Text", for: .normal)
        textButton.addTarget(self, action: #selector(addTextLayer), for: .touchUpInside)

        toolbar.addArrangedSubview(imageButton)
        toolbar.addArrangedSubview(textButton)

        view.addSubview(toolbar)

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            toolbar.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        let layersButton = UIButton(type: .system)
        layersButton.setTitle("Layers", for: .normal)
        layersButton.addTarget(self, action: #selector(showLayerList), for: .touchUpInside)

        let cropButton = UIButton(type: .system)
        cropButton.setTitle("Crop", for: .normal)
        cropButton.addTarget(self, action: #selector(startCropMode), for: .touchUpInside)

        let drawButton = UIButton(type: .system)
        drawButton.setTitle("Draw", for: .normal)
        drawButton.addTarget(self, action: #selector(toggleDrawMode), for: .touchUpInside)

        toolbar.addArrangedSubview(drawButton)
        toolbar.addArrangedSubview(layersButton)
        toolbar.addArrangedSubview(cropButton)

    }
    @objc func toggleDrawMode(_ sender: Any? = nil) {
        view.bringSubviewToFront(canvasView)
        if let doneButton = view.viewWithTag(888) {
            view.bringSubviewToFront(doneButton)       // keep done button visible too
        }
        isDrawingMode.toggle()
        canvasView.isUserInteractionEnabled = isDrawingMode
        layerContainerView.isUserInteractionEnabled = !isDrawingMode

        if isDrawingMode {
            addFloatingDoneButton()

            if let window = view.window, toolPicker == nil {
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
        let image = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
        let imageView = UIImageView(image: image)
        imageView.frame = canvasView.bounds
        imageView.isUserInteractionEnabled = true
        addGestures(to: imageView)

        let layer = EditorLayer(view: imageView, zIndex: layerManager.layers.count)
        layerManager.addLayer(layer, to: layerContainerView)
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
        guard let index = layerManager.layers.firstIndex(where: { $0.id == layer.id }) else { return }
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

        selectedLayer = layerManager.layers.first { $0.view === imageView } // for image
        
        overlay.tag = 999
        overlay.accessibilityHint = "crop:\(imageView.hash)"
        view.addSubview(overlay)
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

}

