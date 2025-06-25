//
//  FontBottomSheetView.swift
//  PKEditor
//
//  Created by Luca Rocchi on 23/06/25.
//


import SwiftUI
//import SUIFontPicker

struct FontBottomSheetView: View {
    @Binding var isVisible:Bool
    @StateObject private var model = EditorModel.shared
    @State var selectedFont : String = ""
    let fontSizes: [CGFloat] = [10,12,14,18, 24, 36, 48, 64, 72, 96,144]
    
    var body: some View {
        // HStack dispone gli elementi orizzontalmente, su una riga.
        VStack{
            HStack {
                // 1. Il testo a sinistra
                Text("Font")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // 2. Lo Spacer occupa tutto lo spazio disponibile nel mezzo,
                //    spingendo gli elementi ai lati opposti.
                Spacer()
                
                // 3. Il bottone a destra
                Button(action: {
                    // Azione da eseguire quando si preme la 'x',
                    // ad esempio chiudere la vista.
                    isVisible = false
                    print("Bottone di chiusura premuto.")
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.gray, .gray.opacity(0.2)) // Colore grigio per icona e sfondo
                }
            }
            HStack(spacing: 5) { // Spazio minimo tra i due campi
                
                // --- Campo Nome Font ---
                Button(action: {
                    print("Azione: Apri selettore dei font...")
                    model.showFontPicker = true
                    // In futuro, qui potremmo aprire un PKFontPicker
                }) {
                    Text(model.currentFont.familyName)
                        .font(.body)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading) // Occupa tutto lo spazio a sx
                        .frame(height: 40)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                // --- Campo Dimensione Font ---
                Menu {
                    // 3. Usiamo un ForEach per creare dinamicamente le voci del menu
                    ForEach(fontSizes.reversed(), id: \.self) { size in
                        Button {
                            // Quando un'opzione viene premuta, aggiorniamo il nostro modello.
                            // Creiamo un nuovo UIFont con la nuova dimensione.
                            let newFont = model.currentFont.withSize(size)
                            model.currentFont = newFont
                            // Il didSet che abbiamo aggiunto a 'currentFont' si occuperà
                            // di chiamare saveFontToUserDefaults() automaticamente.
                            
                        } label: {
                            // Creiamo un'etichetta con il testo e un'icona (il segno di spunta)
                            Label(
                                title: { Text("\(Int(size)) pt") },
                                icon: {
                                    // Mostriamo il segno di spunta solo se la dimensione
                                    // corrisponde a quella attualmente selezionata.
                                    if Int(model.currentFont.pointSize) == Int(size) {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            )
                        }
                    }
                } label: {
                    // 4. Questa è l'etichetta del menu, cioè l'aspetto del "bottone"
                    //    che l'utente vede prima di aprirlo. Mostra la dimensione corrente.
                    Text("\(Int(model.currentFont.pointSize)) pt")
                        .font(.body)
                        .padding(.horizontal)
                        .frame(width: 90)
                        .frame(height: 40)
                        .background(Color.secondary.opacity(0.15))
                        .foregroundColor(.primary) // Assicura che il testo sia leggibile
                        .cornerRadius(8)
                }
            }.frame(maxHeight:.infinity,alignment: .top)
            Spacer()
        }.frame(maxHeight:.infinity,alignment: .top)
            .padding() // Aggiunge un po' di spazio attorno all'intera riga
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $model.showFontPicker){
                
                SUIFontPicker { fontDescriptor in
                    model.currentFont = UIFont(descriptor: fontDescriptor,
                                               size: 64)
                    //customFont is of type UIFont
                }
                
                //FontPicker(isPresented: $model.showFontPicker, selected: $selectedFont)
                //.height(.proportional(0.9))
                //.additionalFontNames(["MySpecialFont"])
                //.excludedFontNames(["Marker Felt"])
                //.backgroundColor(viewModel.fontPickerBackgroundColor)
            }
    }
}

