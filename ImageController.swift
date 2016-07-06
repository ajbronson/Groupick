//
//  ImageController.swift
//  Groupic
//
//  Created by AJ Bronson on 6/27/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import Foundation

import UIKit


class ImageController {
    
    static func fetchImage(url: NSURL, completion: (image: UIImage?) -> Void) {
        
        NetworkController.performURLRequest(url, method: .Get) { (data, error) in
            if let data = data {
                let image = UIImage(data: data)
                completion(image: image)
            }
        }
    }
}