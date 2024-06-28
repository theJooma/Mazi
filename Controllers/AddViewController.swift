
//  AddViewController.swift
//  Mazi
//
//  Created by Jumageldi on 18.06.2024.


import Foundation
import UIKit
import MapKit
import CoreData
import CoreLocation



class AddViewController: UIViewController, UISearchBarDelegate,MKMapViewDelegate,CLLocationManagerDelegate{
    @IBOutlet weak var searchBarAddVC: UISearchBar!
    @IBOutlet weak var locationButtonAddVCout: UIButton!
    @IBOutlet weak var mapViewAddVC: MKMapView!
    
    var locationManager = CLLocationManager()
    var titleId: UUID?
    var passedLocation: NSManagedObject?
    var currentBottomSheetVC: addBottomSheetVc?
    var locations: [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBarAddVC.delegate = self
        setupSearchBarAdd()
        mapViewAddVC.removeAnnotations(mapViewAddVC.annotations)
        mapViewAddVC.delegate = self
        setUpMapView()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gestureRecognizer:)))
        mapViewAddVC.addGestureRecognizer(longPressRecognizer)
        
        // fetchSavedLocations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let location = passedLocation {
            showLocationOnMap(location: location)
        }
    }
    private func showLocationOnMap(location: NSManagedObject){
        let title = location.value(forKey: "title") as? String
        let subtitle = location.value(forKey: "subtitle") as? String
        let imageData = location.value(forKey: "image") as? Data
        let latitude = location.value(forKey: "latitude") as! CLLocationDegrees
        let longitude = location.value(forKey: "longitude") as! CLLocationDegrees
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let annotation = CustomAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        annotation.subtitle = subtitle
        mapViewAddVC.addAnnotation(annotation)
        
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapViewAddVC.setRegion(region, animated: true)
        
        showBottomSheet(for: coordinate, titleId: titleId, title: title, subtitle: subtitle, imageData: imageData)
    }
    
    func setUpMapView(){
        mapViewAddVC.mapType = .hybrid
        
        mapViewAddVC.showsTraffic = true
        mapViewAddVC.showsBuildings = true
        mapViewAddVC.showsPointsOfInterest = true
        
        if let location = passedLocation{
            let latitude = location.value(forKey: "latitude") as! CLLocationDegrees
            let longitude = location.value(forKey: "longitude") as! CLLocationDegrees
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapViewAddVC.setRegion(region, animated: true)
        }
    }
    //MARK: - MapView & Annotation
    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began{
            let touchPoint = gestureRecognizer.location(in: mapViewAddVC)
            let coordinate = mapViewAddVC.convert(touchPoint, toCoordinateFrom: mapViewAddVC)
            
            let annotation = CustomAnnotation()
            annotation.coordinate = coordinate
            mapViewAddVC.addAnnotation(annotation)
            
            showBottomSheet(for: coordinate)
        }
    }
    @objc func handleMapTap(gestureRecognizer: UITapGestureRecognizer){
        if gestureRecognizer.state == .ended{
            if let bottomSheetVC = currentBottomSheetVC{
                present(bottomSheetVC,animated: true, completion: nil)
            }
        }
    }
    
    
    //MARK: - Location Manager
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last{
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            mapViewAddVC.setRegion(region, animated: true)
            
            mapViewAddVC.showsUserLocation = true
            
            let annotation = CustomAnnotation()
            annotation.coordinate = center
            annotation.title = "Your location"
            mapViewAddVC.addAnnotation(annotation)
            locationManager.stopUpdatingLocation()
            
            let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gestureRecognizer:)))
            mapViewAddVC.addGestureRecognizer(longPressRecognizer)
        }
    }
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? CustomAnnotation else {
            print("Bu CustomAnnotation değil!!")
            
            return
        }
        
        print("Annotation seçildi \(annotation.title ?? "No title")")
        
        if let titleId = annotation.titleId{
            print("titleId: \(titleId)")
            if let location = locations.first(where: { ($0.value(forKey: "titleId") as? UUID ) == titleId}){
                let title = location.value(forKey: "title") as? String
                let subtitle = location.value(forKey: "subtitle") as? String
                let imageData = location.value(forKey: "image") as? Data
                showBottomSheet(for: annotation.coordinate, titleId: titleId, title: title, subtitle: subtitle, imageData: imageData)
            }
            else{
                print("İlgili location bulunamadı")
            }
        }
        else{
            print("titleId bulunamadı")
            showBottomSheet(for: annotation.coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error:  Error) {
        print("Kullanıcının konumunu alırken bir hata oluştu gardaş . Ora bir bak daaa??")
    }
    @IBAction func locationButtonClickedAddVC(_ sender: UIButton) {
        locationManager.startUpdatingLocation()
        print("add vc location here")
    }
    
    
    //MARK: - Search Button Methods
    func setupSearchBarAdd() {
        searchBarAddVC.delegate = self
        searchBarAddVC.placeholder = "Search..."
        searchBarAddVC.barStyle = .default
        searchBarAddVC.searchBarStyle = .minimal
        
        // Search bar'ı yuvarlak köşeli ve saydam yapma
        searchBarAddVC.backgroundImage = UIImage()
        if let textfield = searchBarAddVC.value(forKey: "searchField") as? UITextField {
            textfield.backgroundColor = UIColor(white: 1.0, alpha: 0.9)
            textfield.layer.cornerRadius = 10
            textfield.clipsToBounds = true
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if let searchText = searchBar.text{
            searchForLocation(query: searchText)
        }
        
    }
    func searchForLocation(query: String){
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        activeSearch.start { (response, error) in
            if response == nil{
                print("Lokasyon araması yaparken hata oluştu \(String(describing: error))")
            }else{
                self.mapViewAddVC.removeAnnotations(self.mapViewAddVC.annotations)
                
                let latitude = response!.boundingRegion.center.latitude
                let longitude = response!.boundingRegion.center.longitude
                
                let annotation = MKPointAnnotation()
                annotation.title = query
                annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                self.mapViewAddVC.addAnnotation(annotation)
                
                
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                self.mapViewAddVC.setRegion(region, animated: true)
            }
        }
    }
    //MARK: - Bottom Sheet
    func showBottomSheet(for coordinate: CLLocationCoordinate2D, titleId: UUID? = nil, title: String? = nil, subtitle: String? = nil,imageData: Data? = nil ){
        let bottomSheetVC = addBottomSheetVc(nibName: "addBottomSheet", bundle: nil)
        bottomSheetVC.coordinate = coordinate
        bottomSheetVC.titleId = titleId
        bottomSheetVC.existingTitle = title
        bottomSheetVC.existingSubtitle = subtitle
        bottomSheetVC.existingImageData = imageData
        
        bottomSheetVC.saveDataHandler = { [weak self] title, subtitle, image, coordinate, titleId in
            guard let self = self, let coordinate = coordinate else {return}
            if let titleId = titleId{
                // UpdateLocation'u ekle (id varsa güncelleme yapmak için)
                self.updateLocation(titleId: titleId, newTitle: title, newSubtitle: subtitle, newImage: image)
            }else{
                self.saveDataToCoreData(title: title, subtitle: subtitle, image: image, coordinate: coordinate)
                //id yoksa yeni veri eklemek için
                // Save data core data getir
            }
            // Annotation
            let annotation = CustomAnnotation()
            annotation.coordinate = coordinate
            annotation.title = title
            annotation.subtitle = subtitle
            annotation.titleId = titleId
            self.mapViewAddVC.addAnnotation(annotation)
            NotificationCenter.default.post(name: NSNotification.Name("NewLocationSaved"), object: nil)
        }
        if let sheet = bottomSheetVC.sheetPresentationController{
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 26
            
            
        }
        currentBottomSheetVC = bottomSheetVC
        present(bottomSheetVC, animated: true, completion: nil)
    }
    
    // MARK: - CoreData Save Method (CRUD)
    
    func saveDataToCoreData(title: String?, subtitle: String?, image: UIImage?, coordinate: CLLocationCoordinate2D){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        let context = appDelegate.persistentContainer.viewContext
        DispatchQueue.global(qos: .background).async {
        context.perform {
            let entity = NSEntityDescription.entity(forEntityName: "Location", in: context)!
            let newLocation = NSManagedObject(entity: entity, insertInto: context)
            
            let newTitleId = UUID()
            newLocation.setValue(newTitleId, forKey: "titleId")
            newLocation.setValue(title, forKey: "title")
            newLocation.setValue(subtitle, forKey: "subtitle")
            newLocation.setValue(coordinate.latitude, forKey: "latitude")
            newLocation.setValue(coordinate.longitude, forKey: "longitude")
            
            
            let annotation = CustomAnnotation()
            annotation.coordinate = coordinate
            annotation.title = title
            annotation.subtitle = subtitle
            annotation.titleId = newTitleId
            self.mapViewAddVC.addAnnotation(annotation)
            
            if let imageData = image?.jpegData(compressionQuality: 1.0){
                newLocation.setValue(imageData, forKey: "image")
            }
            
            do{
                try context.save()
                
                DispatchQueue.main.async{
                self.locations.append(newLocation)
                NotificationCenter.default.post(name: NSNotification.Name("NewLocationSaved"), object: nil )//userInfo: ["coordinate": coordinate])
            }
            }catch{
                print("Veriler kaydedilirken bir hata oluştu!\(error.localizedDescription)")
            }
            
        }
        
    }
}
    func fetchSavedLocations(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Location")
        
        do {
            let locations = try context.fetch(fetchRequest)
            for location in locations {
                let latitude = location.value(forKey: "latitude") as! CLLocationDegrees
                let longitude = location.value(forKey: "longitude") as! CLLocationDegrees
                let title = location.value(forKey: "title") as? String
                let subtitle = location.value(forKey: "subtitle") as? String
                let titleId = location.value(forKey: "titleId") as? UUID
                
                let annotation = CustomAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                annotation.title = title
                annotation.subtitle = subtitle
                annotation.titleId = titleId
                mapViewAddVC.addAnnotation(annotation)
            }
        }catch{
            print("Lokasyonları getirirken bir hata oluştu! \(error.localizedDescription)")
        }
    }
    
    func updateLocation(titleId: UUID, newTitle: String?, newSubtitle: String?, newImage: UIImage?){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{return}
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Location")
        fetchRequest.predicate = NSPredicate(format: "titleId == %@", titleId as CVarArg)
        
        do{
            if let location = try context.fetch(fetchRequest).first{
                location.setValue(newTitle, forKey: "title")
                location.setValue(newSubtitle, forKey: "subtitle")
                if let newImageData = newImage?.jpegData(compressionQuality: 1.0){
                    location.setValue(newImageData, forKey: "image")
                }
                try context.save()
            }
            
        } catch{
            print("Lokasyonlar yüklenirken bir hata oluştu! \(error)")
        }
    }
    
    func deleteLocation(titleId: UUID){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Location")
        fetchRequest.predicate = NSPredicate(format: "titleId == %@", titleId as CVarArg)
        
        do{
            if let location = try context.fetch(fetchRequest).first {
                context.delete(location)
                try context.save()
            }
        } catch{
            print("Lokasyon verisini silwerken bir hata oluştu")
        }
        
    }
    
}

