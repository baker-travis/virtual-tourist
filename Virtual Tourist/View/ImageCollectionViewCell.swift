//
//  ImageCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Travis Baker on 12/19/18.
//  Copyright © 2018 Travis Baker. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    @IBOutlet var image: UIImageView!
    var photo: Photo? {
        didSet {
            image.image = photo?.uiImage
        }
    }
}
