//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Travis Baker on 12/18/18.
//  Copyright © 2018 Travis Baker. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    // MARK: - Properties
    @IBOutlet weak var mapView: MKMapView!
    var selectedPin: Pin?
    
    let viewContext = DataController.shared.viewContext
    
    let annotationViewReuseIdentifier = "pinAnnotationView"
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    // MARK: - Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupGestureRecognizer()
        mapView.delegate = self
        mapView.register(MKPinAnnotationView.self, forAnnotationViewWithReuseIdentifier: annotationViewReuseIdentifier)
        setupFetchedResultsController()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    // MARK: - Utility Methods
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        try? fetchedResultsController.performFetch()
        
        // load initial pins
        if let pins = fetchedResultsController.fetchedObjects {
            for pin in pins {
                addAnnotation(pin: pin)
            }
        }
    }
    
    func setupGestureRecognizer() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressMapView(_:)))
        
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func handleLongPressMapView(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let location = gestureRecognizer.location(in: mapView)
            let coordinates = mapView.convert(location, toCoordinateFrom: mapView)
            addNewLocationCoordinate(location: coordinates)
        }
    }
    
    func addNewLocationCoordinate(location: CLLocationCoordinate2D) {
        let pin = Pin(context: self.viewContext)
        pin.coordinates = location
        viewContext.perform {
            try? self.viewContext.save()
        }
        
        pin.fetchAllImages()
    }
    
    func addAnnotation(pin: Pin) {
        let annotation = PinAnnotation(pin: pin)
        mapView.addAnnotation(annotation)
    }
}


// MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // TODO: transition to next screen
        mapView.deselectAnnotation(view.annotation, animated: false)
        let pin = (view.annotation as! PinAnnotation).pin
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "latitude == \(pin.latitude) AND longitude == \(pin.longitude)")
        // get up to date pin
        try! viewContext.fetch(fetchRequest)
        if let fetchedPinOpt = try? viewContext.fetch(fetchRequest).first, let fetchedPin = fetchedPinOpt {
            selectedPin = fetchedPin
            performSegue(withIdentifier: "pinSelected", sender: self)
        } else {
            // Show error
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let view: MKAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationViewReuseIdentifier, for: annotation)
        
        view.isDraggable = true
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        if newState == .ending {
            // perform any update
        }
    }
}

extension MapViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            let pin = controller.object(at: newIndexPath!) as! Pin
            addAnnotation(pin: pin)
        default:
            break
        }
    }
}

// MARK: - Segue
extension MapViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let albumVC = segue.destination as! AlbumViewController
        albumVC.pin = selectedPin!
        let backItem = UIBarButtonItem()
        backItem.title = "OK"
        navigationItem.backBarButtonItem = backItem
    }
}

