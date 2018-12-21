//
//  Photo+ImageToData.swift
//  Virtual Tourist
//
//  Created by Travis Baker on 12/19/18.
//  Copyright © 2018 Travis Baker. All rights reserved.
//

import Foundation
import UIKit

extension Photo {
    var uiImage: UIImage? {
        get {
            if let imageData = self.image {
                return UIImage(data: imageData)
            } else {
                return nil
            }
        }
    }
    
    func setImageData(_ photoData: PhotoData) {
        self.id = photoData.id
        self.server = photoData.server
        self.farm = Int16(photoData.farm)
        self.secret = photoData.secret
    }
    
    func fetchImage() throws {
        let url = FlickerAPI.Endpoints.getImageById(farmId: "\(self.farm)", serverId: self.server!, imageId: self.id!, imageSecret: self.secret!).url
        do {
            self.image = try Data(contentsOf: url)
        } catch {
            throw error
        }
    }
}
