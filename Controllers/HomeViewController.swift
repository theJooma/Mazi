//
//  File.swift
//  Mazi
//
//  Created by Jumageldi on 18.06.2024.
//

import Foundation
import UIKit
import MapKit
import CoreLocation
import CoreData

class HomeViewController: UIViewController, UISearchBarDelegate,CLLocationManagerDelegate,MKMapViewDelegate{
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBarHome: UISearchBar!
    @IBOutlet weak var LocationButtonOut: UIButton!
    
    
    
    var locations: [NSManagedObject] = []
    
    let locationManager = CLLocationManager()
    var annotationTitle = ""
    var annotationLatitude: Double = 0.0
    var annotationLongitude: Double = 0.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBarHome.delegate = self
        setupSearchBar()
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        fetchSavedLocations()
        mapSetup()
        NotificationCenter.default.addObserver(self, selector: #selector(handleGoButtonClicked(_:)), name: NSNotification.Name("GoButtonClicked"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fetchSavedLocations), name: NSNotification.Name("NewLocationSaved"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleLocationDeletedNotification), name: NSNotification.Name("LocationDeleted"), object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleLocationDeletedNotification(_ notification: Notification){
        guard let userInfo = notification.userInfo,
              let titleId = userInfo["titleId"] as? UUID else {return}
        
        let annotationsToRemove = mapView.annotations.filter{
            guard let customAnnotation = $0 as? CustomAnnotation else {return false}
            return customAnnotation.titleId == titleId
        }
        
        mapView.removeAnnotations(annotationsToRemove)
    }
    
    @objc func handleNewLocationSavedNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo, let coordinate = userInfo["coordinate"] as? CLLocationCoordinate2D {
            addAnnotation(at: coordinate)
        }
    }
    
    
    func addAnnotation(at coordinate: CLLocationCoordinate2D) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Location")
        fetchRequest.predicate = NSPredicate(format: "latitude == %lf AND longitude == %lf", coordinate.latitude, coordinate.longitude)
        
        do {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{return}
            let context = appDelegate.persistentContainer.viewContext
            if let location = try context.fetch(fetchRequest).first {
                let title = location.value(forKey: "title") as? String
                let subtitle = location.value(forKey: "subtitle") as? String
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = title
                annotation.subtitle = subtitle
                
                mapView.addAnnotation(annotation)
            }
        } catch {
            print("Failed to fetch location to add: \(error.localizedDescription)")
        }
    }
    
    private func mapSetup(){
        mapView.mapType = .standard
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.showsTraffic = false
        mapView.showsBuildings = false
        
    }
    
    //MARK: - Location Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last{
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            mapView.setRegion(region, animated: true)
            
            mapView.showsUserLocation = true
            
            locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error:  Error) {
        print("Kullanıcının konumunu alırken bir hata oluştu gardaş . Ora bir bak daaa??")
    }
    
    @IBAction func LocationButtonHome(_ sender: UIButton) {
        locationManager.startUpdatingLocation()
        print("merhaba")
    }
    
    //MARK: - SearchBar Methods
    func setupSearchBar() {
        searchBarHome.delegate = self
        searchBarHome.placeholder = "Search..."
        searchBarHome.barStyle = .default
        searchBarHome.searchBarStyle = .minimal
        
        // Search bar'ı yuvarlak köşeli ve saydam yapma
        searchBarHome.backgroundImage = UIImage()
        if let textfield = searchBarHome.value(forKey: "searchField") as? UITextField {
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
                self.mapView.removeAnnotations(self.mapView.annotations)
                
                let latitude = response!.boundingRegion.center.latitude
                let longitude = response!.boundingRegion.center.longitude
                
                let annotation = MKPointAnnotation()
                annotation.title = query
                annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                self.mapView.addAnnotation(annotation)
                
                
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                self.mapView.setRegion(region, animated: true)
            }
        }
    }
    
    @objc func fetchSavedLocations(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{return}
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Location")
        
        
        DispatchQueue.global(qos: .userInitiated).async{
            do{
                let locations = try context.fetch(fetchRequest)
                
                DispatchQueue.main.async{
                    self.locations = locations
                    self.updateMapAnnotations()
                }
            }
            catch{
                print("Lokasyon verileri getirilirken bir hata oluştu! \(error.localizedDescription)")
            }
        }
    }
    
    private func updateMapAnnotations(){
        mapView.removeAnnotations(mapView.annotations)
        for location in locations{
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
            
            mapView.addAnnotation(annotation)
        }
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? CustomAnnotation else {
            print("Not a CustomAnn")
            return
        }
        if let titleId = annotation.titleId {
            if let location = locations.first(where: { ($0.value(forKey: "titleId") as? UUID) == titleId }) {
                let title = location.value(forKey: "title") as? String
                let subtitle = location.value(forKey: "subtitle") as? String
                let imageData = location.value(forKey: "image") as? Data
                
                showBottomSheet(for: annotation.coordinate, titleId: titleId, title: title, subtitle: subtitle, imageData: imageData)
            } else {
                print("İlgili location bulunamadı")
            }
        } else {
            print("titleId bulunamadı")
        }
    }
    

    
    
    func showBottomSheet(for coordinate: CLLocationCoordinate2D, titleId: UUID? = nil, title: String? = nil, subtitle: String? = nil, imageData: Data? = nil) {
        let bottomSheetVC = HomeBottomSheetController(nibName: "HomeVCBottomSheet", bundle: nil)
        bottomSheetVC.coordinate = coordinate
        bottomSheetVC.titleId = titleId
        bottomSheetVC.existingTitle = title
        bottomSheetVC.existingSubtitle = subtitle
        bottomSheetVC.existingImageData = imageData
        bottomSheetVC.onGoButtonTapped = {[weak self] in
            self?.navigateToLocation(coordinate: coordinate)
        }
        if let sheet = bottomSheetVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 26
        }
        
        present(bottomSheetVC, animated: true, completion: nil)
    }
    
    func navigateToLocation(coordinate: CLLocationCoordinate2D) {
        let requestLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
            if let placemark = placemarks?.first {
                let newPlacemark = MKPlacemark(placemark: placemark)
                let item = MKMapItem(placemark: newPlacemark)
                item.name = self.annotationTitle
                
                let alert = UIAlertController(title: "Yolculuk Modu Seçin", message: nil, preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: "Sürüş", style: .default, handler: { _ in
                    let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                    item.openInMaps(launchOptions: launchOptions)
                }))
                
                alert.addAction(UIAlertAction(title: "Yürüme", style: .default, handler: { _ in
                    let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking]
                    item.openInMaps(launchOptions: launchOptions)
                }))
                
                alert.addAction(UIAlertAction(title: "Toplu Taşıma", style: .default, handler: { _ in
                    let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeTransit]
                    item.openInMaps(launchOptions: launchOptions)
                }))
                
                alert.addAction(UIAlertAction(title: "İptal", style: .cancel, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @objc func handleGoButtonClicked(_ notification: Notification) {
        if let userInfo = notification.userInfo, let coordinate = userInfo["coordinate"] as? CLLocationCoordinate2D {
            
        }
    }
    
    

    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(overlay: polyline)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 5.0
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.blue
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let annotation = view.annotation {
            annotationTitle = annotation.title! ?? ""
            annotationLatitude = annotation.coordinate.latitude
            annotationLongitude = annotation.coordinate.longitude
            
            // Bottom Sheet'i göster
            showBottomSheet(for: annotation.coordinate, title: annotation.title ?? "", subtitle: annotation.subtitle ?? "")
        }
    }
    
    
    
    
    func fetchLocationDetails(titleId: UUID, completion: @escaping (NSManagedObject?) -> Void){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Location")
        fetchRequest.predicate = NSPredicate(format: "titleId == %@", titleId as CVarArg)
        
        do{
            let locations = try context.fetch(fetchRequest)
            completion(locations.first)
        }
        catch{
            print("Hata! Lokasyon verilerini getirirken bir hata oluştu \(error.localizedDescription)")
            completion(nil)
        }
    }
}



