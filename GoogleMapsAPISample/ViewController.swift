//
//  ViewController.swift
//  GoogleMapsAPISample
//
//  Created by Igor Danilchenko on 07/03/2020.
//  Copyright © 2020 Igor Danilchenko. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let appName = "Application"

    let defaultZoom : Float = 10
    let rostovCoordinate = CLLocationCoordinate2D(latitude: 47.222531, longitude: 39.718705)
    let defaultPadding : CGFloat = 64
    let lineColor = UIColor.blue
    let lineWidth : CGFloat = 2
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var textField: UITextField!
    
    let locationManager = CLLocationManager()
    var currentLocation : CLLocationCoordinate2D?
    var destinationLocation : CLLocationCoordinate2D?
    
    var destinationMarker : GMSMarker?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        startLocationManager()
        
        //move camera to Rostov-on-Don by default
        mapView?.camera = GMSCameraPosition.camera(withLatitude: rostovCoordinate.latitude, longitude: rostovCoordinate.longitude, zoom: defaultZoom)
        
    }
    
    func startLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            //locationManager.startMonitoringSignificantLocationChanges()
        }
        else
        {
            showAlertWith(message: "Turn on location service to use application.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location?.coordinate
        
        if let currentLocation = currentLocation
        {
            mapView?.camera = GMSCameraPosition.camera(withLatitude: currentLocation.latitude, longitude: currentLocation.longitude, zoom: defaultZoom)
        }
        
        mapView.isMyLocationEnabled = true
        
        if let destinationLocation = destinationLocation
        {
            mapView.clear()
            buildRouteFromHere(to: destinationLocation)
        }
        
    }
    
    @IBAction func textFieldTapped(_ sender: Any) {
    
        textField.resignFirstResponder()
        let acController = GMSAutocompleteViewController()
        acController.delegate = self
        present(acController, animated: true, completion: nil)
        
    }
}

extension ViewController: GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        // Get the place name from 'GMSAutocompleteViewController'
        // Then display the name in textField
        textField.text = place.name
        
        // Get coordinate
        destinationLocation = place.coordinate
        
        // Dismiss the GMSAutocompleteViewController when something is selected
        dismiss(animated: true, completion: nil)
        
        mapView.clear()
        if let destinationLocation = destinationLocation
        {
            buildRouteFromHere(to: destinationLocation)
        }
    }
    
    func buildRouteFromHere(to location : CLLocationCoordinate2D) {
        
        mapView?.camera = GMSCameraPosition.camera(withLatitude: location.latitude, longitude: location.longitude, zoom: defaultZoom)
        
        destinationMarker = GMSMarker(position: location)
        destinationMarker?.map = mapView
        
        //Setting the start and end location
        guard let origin: CLLocationCoordinate2D = currentLocation else { return }
        let destination = location
        
        let originString = "\(origin.latitude),\(origin.longitude)"
        let destinationString = "\(destination.latitude),\(destination.longitude)"
        
        let key = AppDelegate.key
        let mode = "driving"
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(originString)&destination=\(destinationString)&mode=\(mode)&key=\(key)"
        
        //Rrequesting Alamofire and SwiftyJSON
        Alamofire.request(url).responseJSON { response in
            print(response.request as Any)  // original URL request
            print(response.response as Any) // HTTP URL response
            print(response.data as Any)     // server data
            print(response.result)   // result of response serialization
            
            var json = JSON()
            do
            {
                json = try JSON(data: response.data!)
            }
            catch
            {
                return
            }

            let routes = json["routes"].arrayValue
            
            if routes.count == 0
            {
                self.showAlertWith(message: "Cannot build route to provided destination.")
                return
            }
            
            for route in routes
            {
                let routeOverviewPolyline = route["overview_polyline"].dictionary
                guard let points = routeOverviewPolyline?["points"]?.stringValue , let path = GMSPath.init(fromEncodedPath: points)
                    else { return }
                
                var bounds = GMSCoordinateBounds()
                
                for index in 1...path.count() {
                    bounds = bounds.includingCoordinate(path.coordinate(at: index))
                }
                
                self.mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: self.defaultPadding))
                
                let polyline = GMSPolyline.init(path: path)
                polyline.strokeColor = self.lineColor
                polyline.strokeWidth = self.lineWidth
                polyline.map = self.mapView
            }
        }
    }
    
    func showAlertWith(message: String) {
        let alert = UIAlertController(title: appName, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // Handle the error
        //print("Error: ", error.localizedDescription)
        showAlertWith(message: error.localizedDescription)
    }
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        // Dismiss when the user canceled the action
        dismiss(animated: true, completion: nil)
    }
}

