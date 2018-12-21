//
//  PhotoData.swift
//  Virtual Tourist
//
//  Created by Travis Baker on 12/20/18.
//  Copyright © 2018 Travis Baker. All rights reserved.
//

import Foundation

struct PhotoData: Codable {
    let id: String
    let secret: String
    let server: String
    let farm: Int
}
