//
//  APIRequests.swift
//  virtualTourist
//
//  Created by Shahad Almutawa on 29/05/1440 AH.
//  Copyright © 1440 Shahad Almutawa. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class APIRequests {

    static func getImages(annotation: MKPointAnnotation, completion: @escaping (String?)-> Void){
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.GalleryPhotosMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.lat: annotation.coordinate.latitude as Double,
            Constants.FlickrParameterKeys.lon: annotation.coordinate.longitude as Double,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.per_page: Constants.FlickrParameterValues.per_page,
            Constants.FlickrParameterKeys.page: self.getRandomPage() as Int,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
            ] as [String : Any]
        
        // create url and request
        let session = URLSession.shared
        let urlString = Constants.Flickr.APIBaseURL + self.escapedParameters(methodParameters as [String:AnyObject])
        let url = URL(string: urlString)!
        let request = URLRequest(url: url)
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            if error != nil { // Handle error...
                completion("Check Your Network Connection")
                return
            }
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                
            } catch {
                completion("Could not parse the data as JSON")
                return
            }
            
            let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject]
            
            let photos = photosDictionary![Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]]
            Pictures.pics.removeAll()
            for photo in photos! {
                let pic = photo[Constants.FlickrResponseKeys.MediumURL] as? String
                Pictures.pics.append(pic!)
            }
            
            completion(nil)
        }

        task.resume()
    }
    
    static func getRandomPage() -> Int {
        let randomPhotoIndex = Int(arc4random_uniform(UInt32(10)))
        
        return randomPhotoIndex
    }
    
    static func escapedParameters(_ parameters: [String:AnyObject]) -> String {
        
        if parameters.isEmpty {
            return ""
        } else {
            var keyValuePairs = [String]()
            
            for (key, value) in parameters {
                
                let stringValue = "\(value)"
                
                let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
                
            }
            return "?\(keyValuePairs.joined(separator: "&"))"
        }
    }
}
