//
//  CustomPKCanvasView.swift
//  PKEditor
//
//  Created by Luca Rocchi on 01/07/25.
//


import PencilKit

class CustomPKCanvasView: PKCanvasView {
    var backgroundView : UIImageView?
    var onLayout: (() -> Void)?
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
            //backgroundView.transform = CGAffineTransform(scaleX: self.zoomScale, y: self.zoomScale)
            
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateBackgroundSize()
        
        onLayout?()
    }
    
}

