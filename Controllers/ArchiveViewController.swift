//
//  ArchiveViewController.swift
//  Mazi
//
//  Created by Jumageldi on 18.06.2024.
//

import Foundation
import UIKit
import CoreData
import CoreLocation
class ArchiveViewController: UIViewController, UITableViewDelegate,UITableViewDataSource{
    @IBOutlet weak var emptyImageView: UIImageView!
    @IBOutlet weak var Label1: UILabel!
    @IBOutlet weak var Label2: UILabel!
    @IBOutlet weak var emptyViewState: UIView!
    @IBOutlet weak var tableView: UITableView!

    
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var locations: [NSManagedObject] = []
    
    var emptyStateView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
      
        setupNotificationObservers()
        fetchSavedLocations()
        checkIfEmpty()
        NotificationCenter.default.addObserver(self, selector: #selector(fetchSavedLocations), name: NSNotification.Name("NewLocationSaved"), object: nil)
        
        

    }
    
    //MARK: - Empty State
    
    func checkIfEmpty(){
        if locations.isEmpty{
            emptyViewState.isHidden = false
            emptyImageView.isHidden = false
            //bottonOut.isHidden = false
            Label1.isHidden = false
            Label2.isHidden = false
            tableView.isHidden = true
        }
        else{
            emptyViewState.isHidden = true
            //bottonOut.isHidden = true
            Label1.isHidden = true
            Label2.isHidden = true
            emptyImageView.isHidden = true
            tableView.isHidden = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchSavedLocations()
        tableView.reloadData()
    }
    
    @objc func handleNewLocationSavedNotification(_ notification: Notification){ //selectorde normalde bu vardı
        fetchSavedLocations()
        if let userInfo = notification.userInfo, let coordinate = userInfo["coordinate"] as? CLLocationCoordinate2D{
            
        }
        tableView.reloadData()
    }
    
    
    
    @objc func fetchSavedLocations(){
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Location")
        
        do{
            locations = try context.fetch(fetchRequest)
            tableView.reloadData()
            checkIfEmpty()
        }catch{
            
            print("Database'dan verileri getirirken hata oluştu! \(error.localizedDescription)")
        }
        
    }
    func setupNotificationObservers() {
           NotificationCenter.default.addObserver(self, selector: #selector(fetchSavedLocations), name: NSNotification.Name("NewLocationSaved"), object: nil)
       }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
        let location = locations[indexPath.row]
        cell.textLabel?.text = location.value(forKey: "title") as? String
        cell.detailTextLabel?.text = location.value(forKey: "subtitle") as? String
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedLocation = locations[indexPath.row]
        performSegue(withIdentifier: "showLocationDetail", sender: selectedLocation)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)  {
        if editingStyle == .delete{
            let deletedLocation = locations[indexPath.row]
            if let titleId = deletedLocation.value(forKey: "titleId") as? UUID{
                print("Attemping to delete location with titleId ")
                deleteLocation(titleId: titleId) { success in
                    if success {
                        NotificationCenter.default.post(name: NSNotification.Name("LocationDeleted"), object: nil, userInfo: ["titleId":titleId])
                        self.locations.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        self.checkIfEmpty()
                    }
                    else{
                        print("Failed to dleete location with titleId")
                        
                        
                    }
                }
            }
            else{
                print("titleId bulunamadı veya silinemedi")
            }
            
            
            
        }
    }
    
    func deleteLocation(titleId: UUID, completion: @escaping (Bool) -> Void) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            completion(false)
            return
        }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Location")
        fetchRequest.predicate = NSPredicate(format: "titleId == %@", titleId as CVarArg)
        
        do {
            let locations = try context.fetch(fetchRequest)
            if let locationToDelete = locations.first {
                context.delete(locationToDelete)
                try context.save()
                completion(true)
            } else {
                print("No location found with titleId: \(titleId)")
                completion(false)
            }
        } catch {
            print("Error deleting location with titleId \(titleId): \(error.localizedDescription)")
            completion(false)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLocationDetail" ,
           let destinationVC = segue.destination as? AddViewController,
           let location = sender as? NSManagedObject {
            destinationVC.passedLocation = location
            
            
        }
        
        
    }
    
    
}
