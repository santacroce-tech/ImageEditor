//
//  CirclePlay.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//


import SwiftUI

struct CircleAdd: View {
    var side:CGFloat = 40
    @StateObject var model = EditorModel.shared
    var body: some View {
        Color(uiColor:.gray)
            .clipShape(Circle())
            .opacity(0.3)
            .frame(width:side,height: side)
            .overlay{
                Image(systemName:"pencil.tip.crop.circle.badge.plus")
            }.onTapGesture {
                model.addLayer()
            }
    }
}
