//
//  CustomPKCanvasView.swift
//  PKEditor
//
//  Created by Luca Rocchi on 01/07/25.
//


import PencilKit

/*
class CustomPKCanvasView: PKCanvasView {
    private let backgroundLayer = CALayer()
    private var backgroundImage: UIImage?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupBackground()
    }
    
    // Metodo per impostare l'immagine di background
    func setBackgroundImage(_ image: UIImage) {
        backgroundImage = image
        updateBackgroundImage()
    }
    
    private func setupBackground() {
        backgroundLayer.frame = CGRect(origin: .zero, size: contentSize)
        layer.insertSublayer(backgroundLayer, at: 0)
    }
    
    private func updateBackgroundImage() {
        guard let image = backgroundImage else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        backgroundLayer.contents = image.cgImage
        backgroundLayer.contentsScale = UIScreen.main.scale
        
        // Opzioni per come l'immagine si adatta:
        
        // Opzione 1: Stretch per riempire tutto il contentSize
        backgroundLayer.contentsGravity = .resize
        
        // Opzione 2: Mantieni aspect ratio, centra
        // backgroundLayer.contentsGravity = .resizeAspect
        
        // Opzione 3: Riempi mantenendo aspect ratio (potrebbe tagliare)
        // backgroundLayer.contentsGravity = .resizeAspectFill
        
        // Opzione 4: Ripeti l'immagine come pattern
        // backgroundLayer.contentsGravity = .center
        // backgroundLayer.contentsScale = 1.0
        
        backgroundLayer.frame = CGRect(origin: .zero, size: contentSize)
        
        CATransaction.commit()
    }
    
    override var contentSize: CGSize {
        didSet {
            updateBackgroundSize()
        }
    }
    
    private func updateBackgroundSize() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backgroundLayer.frame = CGRect(origin: .zero, size: contentSize)
        CATransaction.commit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateBackgroundSize()
    }
}
*/
class CustomPKCanvasView: PKCanvasView {
    var backgroundView : UIImageView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //setupBackground()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //setupBackground()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupBackgroundImage(image:UIImage?) {
        backgroundView?.removeFromSuperview()
        backgroundView = nil
        
         if let image = image {
             backgroundView = UIImageView()
             backgroundView!.backgroundColor = UIColor.clear
             backgroundView!.isUserInteractionEnabled = false
             
             backgroundView!.image = image
             backgroundView!.frame = bounds
             insertSubview(backgroundView!, at: 0)
         }
    }
    
    override var contentSize: CGSize {
        didSet {
            // Quando il contentSize cambia, aggiorna il background
            updateBackgroundSize()
        }
    }
    
    private func updateBackgroundSize() {
        // Il background deve coprire tutto il contenuto
        if let backgroundView = self.backgroundView {
            backgroundView.frame = CGRect(origin: .zero, size: contentSize)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateBackgroundSize()
    
    }
}

