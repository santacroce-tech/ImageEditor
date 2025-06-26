//
//  ContentView.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//

import SwiftUI

import PencilKit
import PhotosUI


//https://stackoverflow.com/questions/70274330/how-do-i-create-a-pkdrawing-programmatically-from-cgpoints/70274331#70274331
//https://gemini.google.com/share/6d0c61a34ebf

struct EditorView: View {
    @StateObject var model = EditorModel.shared
    //@AppStorage("lastToolPickerState")
    //private var storedToolPickerStateData: Data?
    //@State private var toolPickerState: ToolPickerState = ToolPickerState()
     
    @State var showEditorDetail = false
    @State var selectedPhoto: PhotosPickerItem?
    @State var projectName = ""
    
     
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack {
                    //Color.gray.opacity(0.1).ignoresSafeArea()
                    Color(uiColor: UIColor.systemBackground).opacity(1.0)
                        .ignoresSafeArea()
                    
                    
                    ForEach(Array(model.layers.enumerated()), id: \.element.id) { index, layer in
                        LayerContainerView(
                            layer: layer,
                            activeCanvas: $model.activeCanvasId,
                            sharedOffset:$model.contentOffset
                            
                        )
                        .allowsHitTesting(model.activeCanvasId == layer.currentCanvasId)
                        .zIndex(Double(index))
                    }.onAppear {
                        model.setBackgroundColor()
                    }
                    
                  
                    
                    if model.showTextInput {
                        
                        TextInput().zIndex(Double(model.layers.count+1))
                        
                        EditingActionsPanel(
                            onRotateLeft: {
                                // Call the model's function for the active layer
                                model.rotateDrawing( byDegrees: -5)
                            },
                            onRotateRight: {
                                model.rotateDrawing( byDegrees: 5)
                            }
                        )
                        .padding(.top, 10)
                        .padding(.trailing, 10)
                        .frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topTrailing)// Add some space from the top edge
                    }
                }
                
                .background(Color.gray)
                .id(model.projectID)
            }
            .onDisappear {
                // Save current state to UserDefaults
                /*if let encoded = try? JSONEncoder().encode(toolPickerState) {
                 storedToolPickerStateData = encoded
                 }*/
            }
            .sheet(isPresented: $model.showFontSheet) {
                FontBottomSheetView(isVisible:$model.showFontSheet)
                    .presentationDetents([.medium])
                    .background(.background)
                
            }
            /*.onChange(of: toolPickerState) { oldState, newState in
                /*if let encoded = try? JSONEncoder().encode(newState) {
                 storedToolPickerStateData = encoded
                 }*/
            }*/
            
            .onChange(of: model.activeCanvasId) { oldState, newState in
            }
            .sheet(isPresented: $model.showLayerEditorDetail){
                LayersListView(activeCanvas: $model.activeCanvasId)
            }
            .sheet(isPresented: $model.showAccessorySheet) {
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
            
            .onChange(of: model.showPhotoPicker) { oldState, newState in
                let photosURL = URL(string: "photos-redirect://")
                if let url = photosURL {
                     if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                     }
                }
                model.showPhotoPicker = false
            }.fileImporter(
                isPresented: $model.showDocPicker,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async{
                        guard url.startAccessingSecurityScopedResource() else {
                            return
                        }
                        model.loadProject(from: url)
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
            //.photosPicker(isPresented: //$model.showPhotoPicker,selection:$selectedPhoto)
        
        }
        
    }
}


extension String {
    var localize:String {
        return NSLocalizedString(self,comment: "")
    }
}
