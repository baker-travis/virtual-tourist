//
//  AlbumViewController.swift
//  Virtual Tourist
//
//  Created by Travis Baker on 12/19/18.
//  Copyright © 2018 Travis Baker. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class AlbumViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var albumCollectionView: UICollectionView!
    
    var shouldCollectionViewUpdate = false
    
    let viewContext = DataController.shared.viewContext
    
    var pin: Pin!
    
    var deleteIndexPaths: [IndexPath] = []
    var insertIndexPaths: [IndexPath] = []
    var changedIndexPaths: [IndexPath] = []
    var moveIndexPaths: [(old: IndexPath, new: IndexPath)] = []
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    let collectionViewCellReuseIdentifier = "imageCell"
    let annotationViewReuseIdentifier = "albumPinAnnotationView"
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMapView()
        setupFetchedResultsController()
        albumCollectionView.dataSource = self
        albumCollectionView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: "\(pin.latitude)\(pin.longitude)")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print(error)
        }
        
        albumCollectionView.reloadData()
    }
    
    // MARK: - UI Setup
    fileprivate func setupMapView() {
        let mapRegion = MKCoordinateRegion(center: pin.coordinates, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        
        mapView.delegate = self
        mapView.register(MKPinAnnotationView.self, forAnnotationViewWithReuseIdentifier: annotationViewReuseIdentifier)
        
        mapView.addAnnotation(PinAnnotation(pin: pin))
        
        mapView.setRegion(mapRegion, animated: false)
        // Don't allow user to move the map view
        mapView.isUserInteractionEnabled = false
    }
    
    // MARK: - IBActions

    @IBAction func newCollectionPressed(_ sender: Any) {
        pin.fetchAllImages()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - MKMapViewDelegate
extension AlbumViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let view: MKAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationViewReuseIdentifier, for: annotation)
        
        return view
    }
}

// MARK: - UICollectionViewDataSource
extension AlbumViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let image = fetchedResultsController.object(at: indexPath)
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionViewCellReuseIdentifier, for: indexPath) as! ImageCollectionViewCell
        
        if image.uiImage != nil {
            // This will set the cell's imageView as well
            cell.photo = image
        } else {
            cell.image.image = UIImage(imageLiteralResourceName: "Image Placeholder")
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension AlbumViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let image = fetchedResultsController.object(at: indexPath)
        fetchedResultsController.managedObjectContext.delete(image)
        try? fetchedResultsController.managedObjectContext.save()
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension AlbumViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        shouldCollectionViewUpdate = false
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            print("inserted item")
            insertIndexPaths.append(newIndexPath!)
//            albumCollectionView.insertItems(at: [newIndexPath!])
        case .delete:
            print("deleted item")
            deleteIndexPaths.append(indexPath!)
//            albumCollectionView.deleteItems(at: [indexPath!])
        case .update:
            print("updated item")
            changedIndexPaths.append(indexPath!)
//            albumCollectionView.reloadItems(at: [indexPath!])
        case .move:
            print("moved item")
            moveIndexPaths.append((old: indexPath!, new: newIndexPath!))
//            albumCollectionView.moveItem(at: indexPath!, to: newIndexPath!)
        }
        
        shouldCollectionViewUpdate = true
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard shouldCollectionViewUpdate else {
            return
        }
        albumCollectionView.performBatchUpdates({
            self.albumCollectionView.insertItems(at: self.insertIndexPaths)
            self.albumCollectionView.deleteItems(at: self.deleteIndexPaths)
            self.albumCollectionView.reloadItems(at: self.changedIndexPaths)
            for item in self.moveIndexPaths {
                self.albumCollectionView.moveItem(at: item.old, to: item.new)
            }
        }) { (success) in
            self.insertIndexPaths = []
            self.deleteIndexPaths = []
            self.changedIndexPaths = []
            self.moveIndexPaths = []
        }
    }
}
