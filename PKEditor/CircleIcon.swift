//
//  CirclePlay.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//


import SwiftUI

struct CircleIcon: View {
    var side:CGFloat = 40
    @StateObject var model = EditorModel.shared
    var name: String
    var action: (() -> Void)? = nil

    var body: some View {
        Color(uiColor:.gray)
            .clipShape(Circle())
            .opacity(0.3)
            .frame(width:side,height: side)
            .overlay{
                Image(systemName:name)
            }.onTapGesture {
                action?()
            }
    }
}
