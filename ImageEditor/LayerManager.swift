//
//  LayerManager.swift
//  ImageEditor
//
//  Created by Roberto Santacroce on 7/5/25.
//

import UIKit

class LayerManager {
    private(set) var layers: [EditorLayer] = []

    func addLayer(_ layer: EditorLayer, to parent: UIView) {
        layers.append(layer)
        sortLayers()
        parent.addSubview(layer.view)
    }

    func removeLayer(_ id: UUID) {
        if let index = layers.firstIndex(where: { $0.id == id }) {
            layers[index].view.removeFromSuperview()
            layers.remove(at: index)
        }
    }

    func bringToFront(_ id: UUID) {
        if let index = layers.firstIndex(where: { $0.id == id }) {
            let layer = layers.remove(at: index)
            layers.append(layer)
            sortLayers()
        }
    }

    private func sortLayers() {
        for (index, layer) in layers.enumerated() {
            layer.view.layer.zPosition = CGFloat(index)
        }
    }
    
    func reorderLayers(_ newOrder: [EditorLayer]) {
        layers = newOrder
        sortLayers()
    }

    func clear() {
        layers.removeAll()
    }
}
