//
//  PKEditorApp.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//

import SwiftUI

@main
struct PKEditorApp: App {
    var body: some Scene {
        WindowGroup {
            EditorView().onAppear(){
                EditorModel.shared.onPublish = { receivedImage in
                    
                    // Questo codice verrà eseguito solo quando un'altra parte
                    // della tua app chiamerà: model.onPublish?(someImage)
                    
                    print("✅ Evento onPublish ricevuto!")
                    print("L'immagine ricevuta ha dimensioni: \(receivedImage.size)")
                    
                    // Qui puoi fare quello che vuoi con l'immagine,
                    // ad esempio salvarla, mostrarla in una nuova vista, o condividerla.
                }
            }
            
        }
    }
}
