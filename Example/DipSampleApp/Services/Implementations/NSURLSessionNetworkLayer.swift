//
//  NSURLSessionNetworkLayer.swift
//  Dip
//
//  Created by Olivier Halligon on 05/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

class NSURLSessionNetworkLayer : NetworkLayer {
    let session = NSURLSession.sharedSession()
    
    func fetchURL(url: NSURL, completion: NSData? -> Void) {
        let task = session.dataTaskWithURL(url) { (data: NSData?, resp: NSURLResponse?, error: NSError?) -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                completion(data)
            }
        }
        task.resume()
    }
}
