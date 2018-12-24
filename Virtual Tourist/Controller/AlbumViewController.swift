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
    
    // This pattern inspired by and adapted from: https://gist.github.com/Sorix/987af88f82c95ff8c30b51b6a5620657
    var actionsToPerform: [() -> Void] = []
    
    let viewContext = DataController.shared.viewContext
    
    var pin: Pin!
    
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
        pin.deleteAllImages {
            self.pin.fetchAllImages()
        }
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
        actionsToPerform = []
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let sectionIndexSet = IndexSet(integer: sectionIndex)
        
        switch type {
        case .insert:
            actionsToPerform.append {
                self.albumCollectionView.insertSections(sectionIndexSet)
            }
        case .delete:
            actionsToPerform.append {
                self.albumCollectionView.deleteSections(sectionIndexSet)
            }
        case .update:
            actionsToPerform.append {
                self.albumCollectionView.reloadSections(sectionIndexSet)
            }
        case .move:
            assertionFailure()
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            print("inserted item")
            actionsToPerform.append {
                self.albumCollectionView.insertItems(at: [newIndexPath!])
            }
        case .delete:
            print("deleted item")
            actionsToPerform.append {
                self.albumCollectionView.deleteItems(at: [indexPath!])
            }
        case .update:
            print("updated item")
            actionsToPerform.append {
                self.albumCollectionView.reloadItems(at: [indexPath!])
            }
        case .move:
            print("moved item")
            actionsToPerform.append {
                self.albumCollectionView.moveItem(at: indexPath!, to: newIndexPath!)
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        albumCollectionView.performBatchUpdates({
            self.actionsToPerform.forEach({ $0() })
        })
    }
}
