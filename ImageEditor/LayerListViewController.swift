//
//  LayerListViewController.swift
//  ImageEditor
//
//  Created by Roberto Santacroce on 7/5/25.
//

import UIKit

class LayerListViewController: UITableViewController {

    var layers: [EditorLayer] = []
    var onSelect: ((EditorLayer) -> Void)?
    var onDelete: ((EditorLayer) -> Void)?
    var onReorder: (([EditorLayer]) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LayerCell")
        tableView.isEditing = true
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return layers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let layer = layers[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "LayerCell", for: indexPath)
        cell.textLabel?.text = "\(layer.view is UILabel ? "Text" : "Image") Layer \(indexPath.row + 1)"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let layer = layers[indexPath.row]
        onSelect?(layer)
        dismiss(animated: true)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let layer = layers[indexPath.row]
            layers.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            onDelete?(layer)
        }
    }

    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let moved = layers.remove(at: fromIndexPath.row)
        layers.insert(moved, at: to.row)
        onReorder?(layers)
    }
}
