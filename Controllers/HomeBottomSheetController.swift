//
//  HomeBottomSheetController.swift
//  Mazi
//
//  Created by Jumageldi on 27.06.2024.
//

import Foundation
import UIKit
import CoreLocation
import MapKit
class HomeBottomSheetController: UIViewController,CLLocationManagerDelegate, UINavigationControllerDelegate{
    @IBOutlet weak var underImagesView: UIView!
    @IBOutlet weak var selectedImagePresent: UIImageView!
    @IBOutlet weak var goButtonOutlet: UIButton!
    @IBOutlet weak var titleLable: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    var coordinate: CLLocationCoordinate2D?
    var titleId: UUID?
    var existingTitle: String?
    var existingSubtitle: String?
    var existingImageData: Data?
    var onGoButtonTapped: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGoButton()
        titleLable.layer.cornerRadius = 10
        subtitleLabel.layer.cornerRadius = 10
        titleLable.layer.masksToBounds = true
        subtitleLabel.layer.masksToBounds = true
        subtitleLabel.numberOfLines = 0
        subtitleLabel.lineBreakMode = .byWordWrapping
        
        
        if let existingTitle = existingTitle{
            titleLable.text = existingTitle
        }
        if let existingSubtitle = existingSubtitle{
            subtitleLabel.text = existingSubtitle
        }
        if let existingImageData = existingImageData{
            selectedImagePresent.image = UIImage(data: existingImageData)
        }
        
        goButtonOutlet.addTarget(self, action: #selector(goButtonClicked), for: .touchUpInside)
    }
    
    
    
    func setupGoButton(){
        goButtonOutlet.addTarget(self, action: #selector(goButtonClicked), for: .touchUpInside)
    }
    
    
    @IBAction func goButtonClicked(_ sender: UIButton) {
        onGoButtonTapped?()
        print("Go butonuna tıklandı ağam")
//        guard let coordinate = coordinate else{
//            print("Koordinat bulunamadı")
//            return
//        }
        //NotificationCenter.default.post(name: NSNotification.Name("GoButtonClicked"), object: nil, userInfo: ["coordinate": coordinate])
        dismiss(animated: true, completion: nil)
      
    }
    
    
}
