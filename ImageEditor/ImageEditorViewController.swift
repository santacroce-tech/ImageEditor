import UIKit
import PencilKit

class ImageEditorViewController: UIViewController, PKCanvasViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {

    let canvasView = PKCanvasView()
    let layerManager = LayerManager()
    let layerContainerView = UIView()

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
        view.addSubview(canvasView)
        view.sendSubviewToBack(canvasView)
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
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            toolbar.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        let layersButton = UIButton(type: .system)
        layersButton.setTitle("Layers", for: .normal)
        layersButton.addTarget(self, action: #selector(showLayerList), for: .touchUpInside)

        toolbar.addArrangedSubview(imageButton)
        toolbar.addArrangedSubview(textButton)
        toolbar.addArrangedSubview(layersButton)

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



}

