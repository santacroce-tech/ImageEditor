//
//  EditorModel+Menu.swift
//  PKEditor
//
//  Created by Luca Rocchi on 22/06/25.
//

import Foundation
import Combine
import UIKit
@preconcurrency import PencilKit


extension EditorModel {
     func createPopupMenu(){
        // --- Sottomenu "File" ---
        let saveAction = UIAction(title: "Save", image: nil) { _ in
            EditorModel.shared.saveProject()
        }
        let saveAsAction = UIAction(title: "Save as...", image: nil) { _ in
            EditorModel.shared.saveProjectAs = true
        }
        
        let newAction = UIAction(title: "New", image: nil) { _ in
            EditorModel.shared.newProject()
        }
         
         let loadAction = UIAction(title: "from project", image: nil) { _ in
             //EditorModel.shared.loadProject()
             self.showDocPicker = true
         }
         
         let openFromGallery = UIAction(title: "from gallery", image: nil) { _ in
             //EditorModel.shared.loadProject()
             self.showPhotoPicker = true
         }
         
         let openFromCamera = UIAction(title: "from camera", image: nil) { _ in
             //EditorModel.shared.loadProject()
             //self.showDocPicker = true
         }
         let openMenu = UIMenu(title: "Open...", children: [loadAction,openFromGallery,openFromCamera])
       
       
        
        let recentActions = EditorModel.shared.recentProjects.map{ item in
            let recentAction = UIAction(title: item.name, image: nil) { _ in
                EditorModel.shared.loadProject(item.name )
               
            }
            return recentAction
        }
         
        let recentMenu = UIMenu(title: "Open recent", children: recentActions.reversed())
       
        let saveToGallery = UIAction(title: "Save to gallery", image: nil) { _ in
            EditorModel.shared.exportToGallery()
        }
         
         
        let publishAction = UIAction(title: "Publish...", image: nil) { _ in
            EditorModel.shared.publish()
        }
        // Creiamo il sottomenu "File" con le azioni definite sopra
        let fileMenu = UIMenu(title: "File", children: [newAction,openMenu,recentMenu, saveAction, saveAsAction,saveToGallery,publishAction].reversed())
        
        // --- Sottomenu "Layers" ---
        
        
        /*let newLayerAction = UIAction(title: "Add new", image: nil) { _ in
         EditorModel.shared.addLayer()
         }*/
        
        /*
        let undoAction = UIAction(title: "Undo", image: nil) { _ in
            
            EditorModel.shared.undo()
            
        }
        let redoAction = UIAction(title: "Redo", image: nil) { _ in
            
            EditorModel.shared.redo()
            
        }
        */
       
         
        let zoomToFitAction = UIAction(title: "Zoom to fit", image: nil) { _ in
            
            EditorModel.shared.zoomToFit()
            
        }
         let zoomTo1 = UIAction(title: "Zoom 1:1", image: nil) { _ in
             
             EditorModel.shared.zoomTo1of1()
             
         }
         
         /*
         let rotateLeftAction = UIAction(title: "Rotate left", image: nil) { _ in
             EditorModel.shared.rotateDrawing( byDegrees: -5)
         }
         let rotateRightAction = UIAction(title: "Rotate right", image: nil) { _ in
             EditorModel.shared.rotateDrawing( byDegrees: +5)
         }*/
         let layersMenu = UIAction(title: "Layers", image: nil) { _ in
             
             EditorModel.shared.showLayerEditorDetail = true
             
         }
        let editMenu = UIMenu(title: "Edit", children: [zoomToFitAction,zoomTo1,layersMenu].reversed())
        
        // Creiamo il sottomenu "Layers"
        //let layersMenu = UIMenu(title: "Layers", children: [newLayerAction, viewLayersAction].reversed())
      
        // --- Menu Principale e Bottone ---
         let closeMenu = UIAction(title: "Exit", image: nil) { _ in
             EditorModel.shared.exit()
             
         }
        // Creiamo il menu principale che contiene i nostri due sottomenu
        self.mainMenu = UIMenu(title: "", options: .displayInline, children: [fileMenu,editMenu,closeMenu].reversed())
        
       
        // Assegniamo il bottone come accessoryItem del picker
    }
   
}
