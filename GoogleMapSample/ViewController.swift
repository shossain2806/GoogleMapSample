//
//  ViewController.swift
//  GoogleMapSample
//
//  Created by Md. Saber Hossain on 6/2/20.
//  Copyright © 2020 Md. Saber Hossain. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController {

    let tokyo  = CLLocationCoordinate2D(latitude: 35.6804, longitude: 139.7690)//35.6804° N, 139.7690° E
    let dhaka = CLLocationCoordinate2D(latitude: 23.8103, longitude: 90.4125) //23.8103° N, 90.4125° E
    let taipei = CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654) //25.0330° N, 121.5654° E
    let china = CLLocationCoordinate2D(latitude: 35.8617, longitude: 104.1954)//35.8617° N, 104.1954° E
    let vietnaam = CLLocationCoordinate2D(latitude: 14.0583, longitude: 108.2772)//14.0583° N, 108.2772° E
    let singapore = CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)//1.3521° N, 103.8198° E
    
    var mapsController : GoogleMapsController!
    var locations : [CLLocationCoordinate2D] = []
   
    override func viewDidLoad() {
        super.viewDidLoad()
        locations = [dhaka, tokyo, dhaka]
        configureNavigationController()
        createMapView()
        drawSimplePath()
        
    }
    
    func configureNavigationController(){
        navigationItem.title = "Maps"
        let fitlocation = UIBarButtonItem(title: "Fit", style: .plain, target: self, action: #selector(fitlocationPressed(_ :)))
        let animateToLocation1 = UIBarButtonItem(title: "Tokyo", style: .plain, target: self, action: #selector(animateToPressed1(_: )))
        let animateToLocation2 = UIBarButtonItem(title: "Dhaka", style: .plain, target: self, action: #selector(animateToPressed2(_: )))
        navigationItem.rightBarButtonItems = [animateToLocation1, animateToLocation2]
        navigationItem.leftBarButtonItems = [fitlocation]
    }
 
    func createMapView(){
        mapsController = GoogleMapsController()
        mapsController.addMapViewTo(view)
    }
      
    func drawSimplePath(){
        
        let paths  = locations.enumerated().compactMap{ (index, location) -> GMSMutablePath? in
            mapsController.placeMark {
                let marker = GMSMarker()
                marker.position = location
                return marker
            }
            guard index > 0 else {
                return nil
                
            }
            return mapsController.drawPath(startLocation: locations[index - 1], endLocation: location)
        }
      
        DispatchQueue.main.async {
        
            self.mapsController.fitBounds(paths: paths)
        }
  
    }
    
    @objc  func fitlocationPressed(_ sender: Any?){
       
        mapsController.fitBounds(locations: locations)
    }
    
    @objc func animateToPressed1(_ sender: Any?)  {
        mapsController.animateTo(tokyo)
    }

    @objc func animateToPressed2(_ sender: Any?)  {
        mapsController.animateToLocationbyZoomOutAndIn(dhaka)
    }
      
}
