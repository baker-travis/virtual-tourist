//
//  PinAnnotation.swift
//  Virtual Tourist
//
//  Created by Travis Baker on 12/19/18.
//  Copyright © 2018 Travis Baker. All rights reserved.
//

import Foundation
import MapKit

class PinAnnotation: NSObject, MKAnnotation {
    let pin: Pin
    
    var coordinate: CLLocationCoordinate2D {
        return pin.coordinates
    }
    
    init(pin: Pin) {
        self.pin = pin
    }
}
