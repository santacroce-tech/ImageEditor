//
//  LayerContainerView.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//


import SwiftUI
import PencilKit

struct LayerContainerView: View {
    let index:Int
    @ObservedObject var layer: LayerCanvasModel // Osserva direttamente il layer
    @Binding var activeCanvas: Int
    //@Binding var toolPickerState: ToolPickerState
    @Binding var sharedOffset: CGPoint
    var body: some View {
        LayerCanvasView(
            index:index,
            model: layer,
            activeCanvasId: $activeCanvas,
            //toolPickerState: $toolPickerState,
            sharedOffset : $sharedOffset
            
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(layer.visible ? layer.opacity : 0.0) 
       
    }
}
