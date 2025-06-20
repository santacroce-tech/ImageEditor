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

struct ContentView: View {
    @StateObject var model = EditorModel.shared
    //@Environment(\.undoManager) var undoManager
    //@AppStorage("lastToolPickerState")
    //private var storedToolPickerStateData: Data?
    //@State private var toolPickerState: ToolPickerState = ToolPickerState()
    //@State var editorId = UUID().uuidString
    
    @State var showEditorDetail = false
    @State  var selectedPhoto: PhotosPickerItem?
   
    @State var projectName = ""
   
    var body: some View {
        VStack(spacing: 0) {
            
            
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
            
            .onChange(of: model.showPhotoPicker) { oldState, newState in
                var photosURL = URL(string: "photos-redirect://")
                if let url = photosURL {
                                // Controlliamo se l'app può aprire questo tipo di URL
                                if UIApplication.shared.canOpenURL(url) {
                                    // Apriamo l'URL, che lancerà l'app Foto
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
                        guard url.startAccessingSecurityScopedResource() else { // Notice this line right here
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
