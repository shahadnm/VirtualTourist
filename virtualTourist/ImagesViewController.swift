//
//  ImagesViewController.swift
//  virtualTourist
//
//  Created by Shahad Almutawa on 29/05/1440 AH.
//  Copyright © 1440 Shahad Almutawa. All rights reserved.
//

import UIKit
import MapKit
import Kingfisher
import CoreData

class ImagesViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var annotation = MKPointAnnotation()
    var pin: Pin!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var mapView: MKMapView!
    var appDelegate: AppDelegate!
    var dataController:DataController!
    var fetchedResultsController:NSFetchedResultsController<Picture>!
    
    
    fileprivate func setupFetchedResultsController() {
        
        let fetchRequest:NSFetchRequest<Picture> = Picture.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "createdDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil )
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            
            if fetchedResultsController.fetchedObjects?.count == 0 {
                addPic()
            }
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let region = MKCoordinateRegion(center: self.annotation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        self.mapView.setRegion(region, animated: true)
        
        var annotations = [MKPointAnnotation]()
        annotations.append(self.annotation)
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.addAnnotations(annotations)
        self.activityIndicator.startAnimating()
        setupFetchedResultsController()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func addPic() {
        
        DispatchQueue.main.async {
            for index in 0 ..< Pictures.pics.count  {
                
                let imageUrlString = Pictures.pics[index]
                
                let picture = Picture(context: self.dataController.viewContext)
                picture.url = imageUrlString
                picture.createdDate = Date()
                picture.pin = self.pin
                
                
                
                let url = URL(string: imageUrlString)
                let data = try? Data(contentsOf: url!)
                let image = UIImage(data: data!)
                let imageToData = image!.pngData() as Data?
                picture.imageData = imageToData
                
            }
            try? self.dataController.viewContext.save()
            self.activityIndicator.stopAnimating()
        }
    }
    
    @IBAction func newCollectionClicked(_ sender: Any) {
        self.activityIndicator.startAnimating()
        APIRequests.getImages(annotation: self.annotation){ (msg) in
            
            if msg == nil {
                DispatchQueue.main.async {
                    self.deleteAll()
                    self.addPic()
                    self.collectionView.reloadData()
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
    
    func deleteAll(){
        
        let fetchRequest:NSFetchRequest<Picture> = Picture.fetchRequest()
        fetchRequest.includesPropertyValues = false
        do {
            let results = try self.dataController.viewContext.fetch(fetchRequest) as [NSManagedObject]
            for result in results {
                self.dataController.viewContext.delete(result)
            }
            try self.dataController.viewContext.save()
        } catch {
            debugPrint("error")
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
        
        let picToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(picToDelete)
        try? dataController.viewContext.save()
        setupFetchedResultsController()
        self.collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let aPicture = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomeCollectionViewCell", for: indexPath) as! CustomeCollectionViewCell
        
        let imageUrlString = aPicture.url
        cell.image.kf.indicatorType = .activity
        let url = URL(string: imageUrlString!)
        cell.image.kf.setImage(with: url)
        
        return cell
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availablewidth = collectionView.bounds.width - 4
        return CGSize(width: availablewidth/3, height: availablewidth/3)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 1, bottom: 0, right: 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
}

extension ImagesViewController:NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView.reloadData()
    }
}
