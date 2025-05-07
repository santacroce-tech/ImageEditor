//
//  EditorLayer.swift
//  ImageEditor
//
//  Created by Roberto Santacroce on 7/5/25.
//

import UIKit

class EditorLayer {
    let id: UUID = UUID()
    var view: UIView
    var zIndex: Int

    init(view: UIView, zIndex: Int) {
        self.view = view
        self.zIndex = zIndex
    }
}
