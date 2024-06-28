//
//  addBottomSheetVc.swift
//  Mazi
//
//  Created by Jumageldi on 20.06.2024.
//

import Foundation
import UIKit
import CoreLocation
import MapKit
class addBottomSheetVc: UIViewController, CLLocationManagerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    @IBOutlet weak var AddImageView: UIImageView!
    @IBOutlet weak var TitleTextField: UITextField!
    @IBOutlet weak var SubtitleTextField: UITextField!
    @IBOutlet weak var saveButonOut: UIButton!
    @IBOutlet weak var imageViewUnder: UIView!
    @IBOutlet weak var selectImageB: UIButton!
    
    var coordinate: CLLocationCoordinate2D?
    var saveDataHandler: ((String?,String?,UIImage?, CLLocationCoordinate2D?, UUID?) -> Void)?
    var titleId: UUID?
    var existingTitle: String?
    var existingSubtitle: String?
    var existingImageData: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let existingTitle = existingTitle {
            TitleTextField.text = existingTitle
        }
        if let existingSubtitle = existingSubtitle {
            SubtitleTextField.text = existingSubtitle
        }
        if let existingImageData = existingImageData {
            AddImageView.image = UIImage(data: existingImageData)
        }
    }
    
    @IBAction func SaveButtonClicked(_ sender: UIButton) {
        let title = TitleTextField.text
        let subtitle = SubtitleTextField.text
        let image = AddImageView.image
        let coordinate = self.coordinate
        
        
        // veriyi diğer tarafa göndermek için
        saveDataHandler?(title, subtitle, image, coordinate, titleId)
        
        
        dismiss(animated: true, completion: nil)
    }
    
    
    
    @IBAction func selectImageButtonClicked(_ sender: UIButton) {
        DispatchQueue.main.async{
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
           
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectImage = info[.originalImage] as? UIImage{
            AddImageView.image = selectImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
