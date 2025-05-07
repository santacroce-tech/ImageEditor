//
//  CropOverlayView.swift
//  ImageEditor
//
//  Created by Roberto Santacroce on 7/5/25.
//

import UIKit

class CropOverlayView: UIView {

    var cropRect: CGRect = CGRect(x: 50, y: 50, width: 200, height: 200) {
        didSet { setNeedsDisplay() }
    }

    private var dragging = false
    private var dragStartPoint: CGPoint = .zero
    private var originalCropRect: CGRect = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        isUserInteractionEnabled = true

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let path = UIBezierPath(rect: bounds)
        let cropPath = UIBezierPath(rect: cropRect)
        path.append(cropPath)
        path.usesEvenOddFillRule = true

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        layer.mask = maskLayer

        // Draw border
        UIColor.white.setStroke()
        cropPath.lineWidth = 2
        cropPath.stroke()
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)

        switch gesture.state {
        case .began:
            if cropRect.contains(location) {
                dragging = true
                dragStartPoint = location
                originalCropRect = cropRect
            }
        case .changed:
            guard dragging else { return }
            let delta = CGPoint(x: location.x - dragStartPoint.x, y: location.y - dragStartPoint.y)
            cropRect = originalCropRect.offsetBy(dx: delta.x, dy: delta.y)
        case .ended, .cancelled:
            dragging = false
        default: break
        }
    }
}
