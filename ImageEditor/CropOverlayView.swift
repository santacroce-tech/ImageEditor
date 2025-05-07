//
//  CropOverlayView.swift
//  ImageEditor
//
//  Created by Roberto Santacroce on 7/5/25.
//

import UIKit

class CropOverlayView: UIView {

    var cropRect: CGRect = CGRect(x: 80, y: 80, width: 200, height: 200) {
        didSet { setNeedsDisplay() }
    }

    private var activeHandle: Handle?
    private var startPoint: CGPoint = .zero
    private var originalRect: CGRect = .zero

    private enum Handle {
        case topLeft, topRight, bottomLeft, bottomRight, move
    }

    private let handleSize: CGFloat = 30

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

        // Dimmed background with hole
        let path = UIBezierPath(rect: bounds)
        let cropPath = UIBezierPath(rect: cropRect)
        path.append(cropPath)
        path.usesEvenOddFillRule = true

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        layer.mask = maskLayer

        // White border
        UIColor.white.setStroke()
        cropPath.lineWidth = 2
        cropPath.stroke()

        // Draw handles
        for handle in handleFrames() {
            UIColor.white.setFill()
            UIBezierPath(rect: handle).fill()
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)

        switch gesture.state {
        case .began:
            activeHandle = handle(at: location) ?? (cropRect.contains(location) ? .move : nil)
            startPoint = location
            originalRect = cropRect

        case .changed:
            guard let handle = activeHandle else { return }
            let dx = location.x - startPoint.x
            let dy = location.y - startPoint.y

            var newRect = originalRect

            switch handle {
            case .topLeft:
                newRect.origin.x += dx
                newRect.origin.y += dy
                newRect.size.width -= dx
                newRect.size.height -= dy
            case .topRight:
                newRect.origin.y += dy
                newRect.size.width += dx
                newRect.size.height -= dy
            case .bottomLeft:
                newRect.origin.x += dx
                newRect.size.width -= dx
                newRect.size.height += dy
            case .bottomRight:
                newRect.size.width += dx
                newRect.size.height += dy
            case .move:
                newRect.origin.x += dx
                newRect.origin.y += dy
            }

            cropRect = newRect.integral
        case .ended, .cancelled:
            activeHandle = nil
        default:
            break
        }
    }

    private func handleFrames() -> [CGRect] {
        return [
            CGRect(x: cropRect.minX - handleSize/2, y: cropRect.minY - handleSize/2, width: handleSize, height: handleSize),
            CGRect(x: cropRect.maxX - handleSize/2, y: cropRect.minY - handleSize/2, width: handleSize, height: handleSize),
            CGRect(x: cropRect.minX - handleSize/2, y: cropRect.maxY - handleSize/2, width: handleSize, height: handleSize),
            CGRect(x: cropRect.maxX - handleSize/2, y: cropRect.maxY - handleSize/2, width: handleSize, height: handleSize)
        ]
    }

    private func handle(at point: CGPoint) -> Handle? {
        let frames = handleFrames()
        if frames[0].contains(point) { return .topLeft }
        if frames[1].contains(point) { return .topRight }
        if frames[2].contains(point) { return .bottomLeft }
        if frames[3].contains(point) { return .bottomRight }
        return nil
    }
}
