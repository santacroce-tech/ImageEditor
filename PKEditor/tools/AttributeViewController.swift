/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller for the attribute area in the property popover.
*/

import UIKit

class AttributeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    let attributeModel: AttributeViewController.Model
    var collectionView: UICollectionView?
    lazy var viewHeight = 50.0
    lazy var margin = 7.0
    lazy var cellHeight = viewHeight - (margin * 2)

    init(attributeModel: AttributeViewController.Model) {
        self.attributeModel = attributeModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reload() {
        collectionView?.reloadData()
    }

    override func viewDidLoad() {
        let itemsPerRow: CGFloat = 5
            let spacing: CGFloat = 5.0 // Spazio sia orizzontale che verticale

            // --- 2. CALCOLO DINAMICO DELL'ALTEZZA ---
            let totalItems = CGFloat(attributeModel.attributes.count)
            // Calcoliamo il numero di righe necessarie (arrotondando per eccesso)
            let numberOfRows = ceil(totalItems / itemsPerRow)
            // Calcoliamo l'altezza totale: (N righe * altezza cella) + (N-1 spaziature) + (margini sopra e sotto)
            let totalContentHeight = (numberOfRows * cellHeight) + (max(0, numberOfRows - 1) * spacing)
            let totalViewHeight = totalContentHeight + (margin * 2)
            
            // Aggiorniamo la dimensione preferita del popover per adattarsi al contenuto
            preferredContentSize = CGSize(width: 200, height: totalViewHeight)
            view.backgroundColor = .clear

            // --- 3. CONFIGURAZIONE DEL LAYOUT ---
            let layout = UICollectionViewFlowLayout()
            // La direzione dello scorrimento ora è verticale
            layout.scrollDirection = .vertical
            // Definiamo la dimensione di ogni cella
            layout.itemSize = CGSize(width: cellHeight, height: cellHeight)
            // Definiamo lo spazio verticale tra le righe
            layout.minimumLineSpacing = spacing
            // Definiamo lo spazio orizzontale tra gli elementi sulla stessa riga
            layout.minimumInteritemSpacing = spacing

            // Il resto della creazione della CollectionView rimane invariato
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
            collectionView.showsVerticalScrollIndicator = true
            collectionView.showsHorizontalScrollIndicator = false
            collectionView.backgroundColor = .clear
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.register(Cell.self, forCellWithReuseIdentifier: "Cell")

            self.collectionView = collectionView
            view.addSubview(collectionView)
        // Sets constraints for the collection view.
        let topConstraint = NSLayoutConstraint(item: collectionView,
                                               attribute: .top,
                                               relatedBy: .equal,
                                               toItem: view,
                                               attribute: .top,
                                               multiplier: 1.0,
                                               constant: margin)
        
        let bottomConstraint = NSLayoutConstraint(item: collectionView,
                                                  attribute: .bottom,
                                                  relatedBy: .equal,
                                                  toItem: view,
                                                  attribute: .bottom,
                                                  multiplier: 1.0,
                                                  constant: -margin)

        let leadingConstraint = NSLayoutConstraint(item: collectionView,
                                                   attribute: .leading,
                                                   relatedBy: .equal,
                                                   toItem: view,
                                                   attribute: .leading,
                                                   multiplier: 1.0,
                                                   constant: margin)

        let trailingConstraint = NSLayoutConstraint(item: collectionView,
                                                    attribute: .trailing,
                                                    relatedBy: .equal,
                                                    toItem: view,
                                                    attribute: .trailing,
                                                    multiplier: 1.0,
                                                    constant: -margin)

        NSLayoutConstraint.activate([
            topConstraint,
            bottomConstraint,
            leadingConstraint,
            trailingConstraint
        ])
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attributeModel.attributes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)

        let name = attributeModel.attributes[indexPath.item].name
        let currentImage = attributeModel.attributes[indexPath.item].image
        let image = attributeModel.shouldApplyColor ? currentImage.withTintColor(attributeModel.color, renderingMode: .alwaysOriginal) : currentImage

        let frame = CGRect(x: 0, y: 0, width: cellHeight, height: cellHeight)
        let button = SelectButton(frame: frame, name: name, image: image) { name in
            self.attributeModel.selectedAttribute = (name: name, image: image)
            self.collectionView?.reloadData()
        }
        button.contentMode = .scaleAspectFit
        button.setSelected( name == attributeModel.selectedAttribute.name)

        cell.addSubview(button)

        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellHeight, height: cellHeight)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
}

extension AttributeViewController {
    typealias AttributeType = (name: String, image: UIImage)

    class Model {
        var shouldApplyColor = true
        var attributes: [AttributeType] = []
        var previousSelectedAttribute: AttributeType?
        var selectedAttribute: AttributeType {
            didSet {
                if selectedAttribute.name != previousSelectedAttribute?.name {
                    selectedAttributeDidChange?(selectedAttribute)
                }
            }
        }

        var selectedImage: UIImage? {
            selectedAttribute.image
        }
        var color: UIColor = .black
        var selectedAttributeDidChange: ((AttributeType) -> Void)?

        init(attributes: [(name: String, image: UIImage)], selectedAttribute: AttributeType, color: UIColor) {
            self.attributes = attributes
            self.selectedAttribute = selectedAttribute
            self.color = color
        }
    }
}

fileprivate extension AttributeViewController {

    class Cell: UICollectionViewCell {
        var customSubview: UIView?

        override func addSubview(_ view: UIView) {
            super.addSubview(view)
            self.customSubview = view
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            customSubview?.removeFromSuperview()
        }
    }

    /// A button for presenting and selecting attributes.
    class SelectButton: UIButton {

        typealias ActionClosure = (String) -> Void
        
        let name: String
        var action: ActionClosure?

        init(frame: CGRect, name: String, image: UIImage, action: ActionClosure? = nil) {
            self.name = name
            self.action = action
            super.init(frame: frame)
            setImage(image, for: .normal)
            addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc
        private func buttonTapped() {
            action?(name)
        }

        func setSelected(_ isSelected: Bool) {
            if isSelected {
                addBorder(color: .gray, width: 2, cornerRadius: 10)
            } else {
                removeBorder()
            }
        }

        func removeBorder() {
            self.layer.borderColor = nil
            self.layer.borderWidth = 0
            self.clipsToBounds = false
        }

        func addBorder(color: UIColor, width: CGFloat, cornerRadius: CGFloat) {
            self.layer.borderColor = color.cgColor
            self.layer.borderWidth = width
            self.layer.cornerRadius = cornerRadius
            self.clipsToBounds = false
        }
    }
}
