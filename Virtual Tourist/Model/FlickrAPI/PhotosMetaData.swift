//
//  PhotosMetaData.swift
//  Virtual Tourist
//
//  Created by Travis Baker on 12/20/18.
//  Copyright © 2018 Travis Baker. All rights reserved.
//

import Foundation

struct PhotosMetaData: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [PhotoData]
}
