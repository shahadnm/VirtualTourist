//
//  ViewController.swift
//  virtualTourist
//
//  Created by Shahad Almutawa on 29/05/1440 AH.
//  Copyright © 1440 Shahad Almutawa. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var annotations = [MKPointAnnotation]()
    var dataController:DataController!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            if fetchedResultsController.fetchedObjects?.count != 0 {
                print(fetchedResultsController.fetchedObjects?.count)
                showOnMap()
            }
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(addPins(longGesture:)))
        
        mapView.addGestureRecognizer(longGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    
    func showOnMap(){
        let aPin = fetchedResultsController.fetchedObjects
        annotations.removeAll()
        
        for pin in aPin! {
        
        let location = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)

        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotations.append(annotation)
        self.mapView.addAnnotation(annotation)
        }
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.addAnnotations(annotations)
    }
    @objc func addPins(longGesture: UIGestureRecognizer) {
 
        if longGesture.state == .began {
        let touchPoint = longGesture.location(in: mapView)
        let coords = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let location = CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
         annotations.append(annotation)
        addPin(annotation: annotation)
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.addAnnotations(annotations)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func addPin(annotation : MKPointAnnotation){
DispatchQueue.main.async {
    let pin = Pin(context: self.dataController.viewContext)
        pin.latitude = annotation.coordinate.latitude
        pin.longitude = annotation.coordinate.longitude
        pin.createdDate = Date()
        }
    try? self.dataController.viewContext.save()
    //setupFetchedResultsController()
    }
    
    func findPins(annotation: CLLocationCoordinate2D) -> Pin? {
      
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let predicate = NSPredicate(format: "latitude == %lf AND longitude == %lf", annotation.latitude, annotation.longitude)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "createdDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let pin = try? dataController.viewContext.fetch(fetchRequest).first

        return pin!
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    
        
        APIRequests.getImages(annotation: view.annotation as! MKPointAnnotation){ (msg) in

            if(msg == nil){
                DispatchQueue.main.async {
                    
                    let controller = self.storyboard!.instantiateViewController(withIdentifier: "ImagesViewController") as! ImagesViewController
                    controller.annotation = view.annotation as! MKPointAnnotation
                    controller.dataController = self.dataController
                    
                    controller.pin = self.findPins(annotation: (view.annotation?.coordinate)!)
                    self.navigationController!.pushViewController(controller, animated: true)
                }
            }
            else {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
       }
    }
}
