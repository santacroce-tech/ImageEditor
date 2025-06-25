//
//  LayersListView.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//


import SwiftUI

struct LayersListView: View {
    @ObservedObject var model: EditorModel = EditorModel.shared
    @Environment(\.dismiss) private var dismiss // Per chiudere lo sheet
    @Binding var activeCanvas: Int // <-- 1. Accetta il binding
    
    var body: some View {
        // NavigationView è necessaria per avere una barra del titolo e i pulsanti
        NavigationView {
            List {
                // Itera sui layer per creare le righe
                ForEach(model.layers) { layer in
                    LayerRowView(layer: layer,activeCanvas: $activeCanvas)
                        .tag(layer.currentCanvasId)
                }
                .onMove(perform: moveLayer) // Abilita il drag-and-drop
                .onDelete(perform: deleteLayer) // <-- 1. AGGIUNGI QUESTO MODIFICATORE
                
            }
            .onAppear {
                //model.objectWillChange.send()
            }
            .listStyle(.plain)
            .navigationTitle("Layers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        model.addLayer()
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
            }
        }
    }
    
    /// Funzione chiamata quando un layer viene spostato nella lista.
    /// Aggiorna direttamente l'ordine nell'array del modello.
    private func moveLayer(from source: IndexSet, to destination: Int) {
        model.layers.move(fromOffsets: source, toOffset: destination)
        model.setBackgroundColor()
    }
    private func deleteLayer(at offsets: IndexSet) { // <-- 2. AGGIUNGI QUESTA FUNZIONE
        if model.layers.count > 1 {
            model.layers.remove(atOffsets: offsets)
            model.setBackgroundColor()
        }
    }
}
