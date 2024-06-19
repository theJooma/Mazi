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
class HomeViewController: UIViewController, UISearchBarDelegate,CLLocationManagerDelegate,MKMapViewDelegate{
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBarHome: UISearchBar!
    @IBOutlet weak var LocationButtonOut: UIButton!
   
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBarHome.delegate = self
        setupSearchBar()
    
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
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
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
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
    
}
