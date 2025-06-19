//
//  ContentView.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//

import SwiftUI

import PencilKit


//https://stackoverflow.com/questions/70274330/how-do-i-create-a-pkdrawing-programmatically-from-cgpoints/70274331#70274331
//https://gemini.google.com/share/6d0c61a34ebf

struct ContentView: View {
    @StateObject var model = EditorModel.shared
    //@Environment(\.undoManager) var undoManager
    
    
    //@AppStorage("lastToolPickerState")
    //private var storedToolPickerStateData: Data?
    
    @State private var toolPickerState: ToolPickerState = ToolPickerState()
    
    
    @State var editorId = UUID().uuidString
    @State var showEditorDetail = false
    @State var projectName = ""
  
    var body: some View {
        VStack(spacing: 0) {
            /*HStack{
                /*Picker("Active Canvas", selection: $model.activeCanvasId) {
                    ForEach(model.layers) { layer in // Usa model.layers
                        Text(String(layer.currentCanvasId)).tag(layer.currentCanvasId)
                    }
                }
                .pickerStyle(.segmented)
                 */
                if UIDevice.current.userInterfaceIdiom == .phone {
                    Spacer()
                    Button {
                        model.undo()
                    } label: {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .font(.title2)
                    }
                    .disabled(model.canUndo == false) //
                    Button {
                        model.redo()
                    } label: {
                        Image(systemName: "arrow.uturn.forward.circle")
                            .font(.title2)
                    }
                    .disabled(model.canRedo == false)
                    Spacer()
                    Button {
                        // Chiama la nuova funzione sul modello, passando l'ID del layer attivo
                        model.rotateLastStroke(for: model.activeCanvasId, byDegrees: 10)
                        
                        //model.rotateSelection(for: activeCanvas, byDegrees: 45)
                    } label: {
                        Image(systemName: "rotate.right").font(.title2)
                    }
                    
                    Button {
                       
                        model.rotateLastStroke(for: model.activeCanvasId, byDegrees: -10)
                        
                        //model.rotateSelection(for: activeCanvas, byDegrees: 45)
                    } label: {
                        Image(systemName: "rotate.left").font(.title2)
                    }
                    
                }
                
                //Spacer()
                
                /*CircleIcon(name:"pencil.tip"){
                    if let canvas = model.layers.first(where: {$0.currentCanvasId == activeCanvas}){
                        canvas.pickerVisibility.toggle()
                        //canvas.setDrawPolicy(policy: canvas.drawingPolicy == .anyInput ? .pencilOnly : .anyInput)
                    }
                }*/
            
            }
            .padding()
             */
            
            /*
             HStack {
             ForEach(model.layers) { layer in // Usa model.layers
             Button(String(layer.currentCanvasId)) {
             layer.opacity = layer.opacity == 0 ? 1 : 0
             // RIMUOVI: editorId = UUID().uuidString
             }.padding(.horizontal)
             }
             }
             */
            
            ZStack {
                //Color.gray.opacity(0.1).ignoresSafeArea()
                Color(uiColor: UIColor.systemBackground).opacity(1.0)
                    .ignoresSafeArea()
                
              
                
                ForEach(Array(model.layers.enumerated()), id: \.element.id) { index, layer in
                    LayerContainerView(
                        layer: layer,
                        activeCanvas: $model.activeCanvasId,
                        toolPickerState: $toolPickerState,
                        sharedOffset:$model.sharedContentOffset
                        
                    )
                    .allowsHitTesting(model.activeCanvasId == layer.currentCanvasId)
                    .zIndex(Double(index))
                }
            }
            //.padding(20.0)
            .background(Color.gray)
            .id(model.projectID)
            .onAppear {
                //model.undoManager = undoManager
                /*if let data = storedToolPickerStateData {
                 if let loadedState = try? JSONDecoder().decode(ToolPickerState.self, from: data) {
                 toolPickerState = loadedState
                 }
                 }*/
            }
            .onDisappear {
                // Save current state to UserDefaults
                /*if let encoded = try? JSONEncoder().encode(toolPickerState) {
                 storedToolPickerStateData = encoded
                 }*/
            }
            .onChange(of: toolPickerState) { oldState, newState in
                /*if let encoded = try? JSONEncoder().encode(newState) {
                 storedToolPickerStateData = encoded
                 }*/
            }
            
            .onChange(of: model.activeCanvasId) { oldState, newState in
                //editorId = UUID().uuidString
            }
            .sheet(isPresented: $model.showLayerEditorDetail){
                LayersListView(activeCanvas: $model.activeCanvasId)
            }
            .sheet(isPresented: $model.isShowingAccessorySheet) {
                EmptyView()
            }
            .alert("Save project as".localize,isPresented: $model.saveProjectAs) {
                TextField("Name".localize, text: $projectName)
                
                Button("Ok".localize){
                    if !projectName.isEmpty{
                        model.saveProject(name: projectName)
                    }
                }
                
                Button("Cancel".localize,role:.cancel){
                }
            }
        }
        
    }
}


extension String {
    var localize:String {
        return NSLocalizedString(self,comment: "")
    }
}
