//
//  CirclePlay.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//


import SwiftUI

struct CircleMenu: View {
    var side:CGFloat = 40
    @State var showEditorDetail = false
    @Binding var activeCanvas: Int // <-- 1. Accetta il binding

    var body: some View {
        Color(uiColor:.gray)
            .clipShape(Circle())
            .opacity(0.3)
            .frame(width:side,height: side)
            .overlay{
                Image(systemName:"square.3.layers.3d.top.filled")
                    
            }.onTapGesture {
                showEditorDetail.toggle()
            }.sheet(isPresented: $showEditorDetail){
                LayersListView(activeCanvas: $activeCanvas)
            }
    }
}
