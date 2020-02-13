//
//  GoogleMapsController.swift
//  GoogleMapSample
//
//  Created by Md. Saber Hossain on 6/2/20.
//  Copyright © 2020 Md. Saber Hossain. All rights reserved.
//

import UIKit
import GoogleMaps


class GoogleMapsController : NSObject{
    
    private let mapView : GMSMapView
    
    override init() {
        self.mapView = GMSMapView(frame: .zero)
        super.init()
        self.mapView.delegate = self
    }
    
    static func setAPIKeyForMapServies(apiKey: String) {
        GMSServices.provideAPIKey(apiKey)
    }
    
    func styleMap(resourceUrl: URL?){
        guard let url = resourceUrl else { return }
        do{
            mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: url)
        }catch (let error){
            print(error.localizedDescription)
        }
    }
    
    func addMapViewTo(_ view: UIView){
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    func zoom(enable: Bool){
        mapView.settings.zoomGestures = enable
    }
       
    func myLocation(enable: Bool){
        mapView.settings.myLocationButton = enable
    }
    
}

//MARK:- Google Map Draw
extension GoogleMapsController{
  
    func drawPath(startLocation: CLLocationCoordinate2D, endLocation: CLLocationCoordinate2D) -> GMSMutablePath{
     
        let path = bezierPath(from: startLocation, to: endLocation)
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 2
        let styles = [GMSStrokeStyle.solidColor(.red),
                      GMSStrokeStyle.solidColor(.clear)]
        let lengths: [NSNumber] = [100000, 50000]
        polyline.spans = GMSStyleSpans(polyline.path!, styles, lengths, GMSLengthKind.rhumb)
        polyline.map = mapView
        
        return path
    }
    
    func bezierPath(from startLocation: CLLocationCoordinate2D, to endLocation: CLLocationCoordinate2D) -> GMSMutablePath{
    
        let distance = GMSGeometryDistance(startLocation, endLocation)
        let midPoint = GMSGeometryInterpolate(startLocation, endLocation, 0.5)
     
        let midToStartLocHeading = GMSGeometryHeading(midPoint, startLocation)
       
        
        let controlPointAngle = 360.0 - (90.0 - midToStartLocHeading)
        let controlPoint = GMSGeometryOffset(midPoint, distance / 2.0 , controlPointAngle)
        
        let path = GMSMutablePath()
        
        let stepper = 0.05
        let range = stride(from: 0.0, through: 1.0, by: stepper)// t = [0,1]
        
        func calucaluatePoint(when t: Double) -> CLLocationCoordinate2D{
            let t1 = (1.0 - t)
            let latitude = t1 * t1 * startLocation.latitude + 2 * t1 * t * controlPoint.latitude + t * t * endLocation.latitude
            let longitude = t1 * t1 * startLocation.longitude + 2 * t1 * t * controlPoint.longitude + t * t * endLocation.longitude
            let point = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            return point
        }
        
        range.compactMap{ calucaluatePoint(when: $0) }.forEach{path.add($0)}
        
        // draw direction marker on middle of the path. t = [0, 1]
        let t = 0.5
        let point1 = calucaluatePoint(when: t - stepper)
        let point2 = calucaluatePoint(when: t)
        let iconRotation = GMSGeometryHeading(point1, point2)
        self.placeDirectionMarker(on: point2, heading: iconRotation)
     
        return path
    }
    
    //circle solution
    func circularPath(from startLocation: CLLocationCoordinate2D, to endLocation: CLLocationCoordinate2D) -> GMSMutablePath {
       
        let constant = 1.0
        
        let distance = GMSGeometryDistance(startLocation, endLocation)
        let heading = GMSGeometryHeading(startLocation, endLocation)
        
        //Midpoint position
        let midPoint = GMSGeometryOffset(startLocation, distance * 0.5, heading)
      
        //Apply some mathematics to calculate position of the circle center
        let x = (1 - constant * constant) * distance * 0.5 / (2 * constant)
        let r = (1 + constant * constant) * distance * 0.5 / (2 * constant)
        let circleCenter =  GMSGeometryOffset(midPoint, x, heading + 90.0)
      
        //Calculate heading between circle center and two points
        let h1 = GMSGeometryHeading(circleCenter, startLocation)
        let h2 = GMSGeometryHeading(circleCenter, endLocation)
        
        //Calculate positions of points on circle border and add them to polyline options
        let path = GMSMutablePath()
        let numPoints = 100
        let step : Double = (h2 - h1) / Double(numPoints)
        for pointNo in 0..<numPoints{
            let point = GMSGeometryOffset(circleCenter, r, h1 + Double(pointNo) * step)
            path.add(point)
        }
    
        //draw direction marker on middle of the path.
        let directionMarkerPoint = Double(numPoints) / 2.0
        let directionMarkerPrevPoint = directionMarkerPoint - 1.0
        let position = GMSGeometryOffset(circleCenter, r, h1 + directionMarkerPoint * step)
        let prevPosition = GMSGeometryOffset(circleCenter, r, h1 + directionMarkerPrevPoint * step)
        let directionHeading = GMSGeometryHeading(prevPosition, position)
        self.placeDirectionMarker(on: position, heading: directionHeading)
        return path
    }
}

//MARK:- Google Map Marker

extension GoogleMapsController{
    
    func placeMark(marker: () -> GMSMarker){
        marker().map = mapView
    }
    
    func placeDirectionMarker(on postion: CLLocationCoordinate2D, heading: CLLocationDirection){
        self.placeMark {
            let marker = GMSMarker()
            marker.icon = UIImage(named: "aeroplane")
            marker.position = postion
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
            marker.isFlat = true
            marker.title = "indicator"
            marker.rotation = heading
            return marker
        }
    }
}

//MARK:- Animations with Map
extension GoogleMapsController{
 
    func fitBounds(locations: [CLLocationCoordinate2D]){
        var bounds = GMSCoordinateBounds()
        locations.forEach { bounds = bounds.includingCoordinate($0) }
        let update = GMSCameraUpdate.fit(bounds, withPadding: 50)
        mapView.moveCamera(update)
    }
       
    func fitBounds(paths: [GMSPath]){
         
        var bounds = GMSCoordinateBounds()
        paths.forEach{ bounds = bounds.includingPath($0) }
        let update = GMSCameraUpdate.fit(bounds, withPadding: 50)
        mapView.moveCamera(update)
    }
    
    func animateTo(_ location: CLLocationCoordinate2D){
        guard CLLocationCoordinate2DIsValid(location) else{
            return
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(2.0)
        
        let camera = GMSCameraPosition(target: location, zoom: 8.0, bearing: 50.0, viewingAngle: 60.0)
        mapView.animate(to: camera)
        CATransaction.commit()
    }
       
    func animateToLocationbyZoomOutAndIn(_ location: CLLocationCoordinate2D){
        guard CLLocationCoordinate2DIsValid(location) else{
            return
        }
        mapView.layer.cameraLatitude = location.latitude
        mapView.layer.cameraLongitude = location.longitude
        mapView.layer.cameraBearing = 0
           
        //Access the GMSLayer Directly to modify the following properties with a specified time function and duration
           
        let timeFunctionCurve = CAMediaTimingFunction(name: .easeInEaseOut)
           
        let latitudeAnimation = CABasicAnimation(keyPath: kGMSLayerCameraLatitudeKey)
        latitudeAnimation.duration = 2.0
        latitudeAnimation.timingFunction = timeFunctionCurve
        latitudeAnimation.toValue = location.latitude
        mapView.layer.add(latitudeAnimation, forKey: kGMSLayerCameraLatitudeKey)
    
        let longitudeAnimation = CABasicAnimation(keyPath: kGMSLayerCameraLongitudeKey)
        longitudeAnimation.duration = 2.0
        longitudeAnimation.timingFunction = timeFunctionCurve
        longitudeAnimation.toValue = location.longitude
        mapView.layer.add(longitudeAnimation, forKey: kGMSLayerCameraLongitudeKey)
           
        let cameraBearingAnimtaion = CABasicAnimation(keyPath: kGMSLayerCameraBearingKey)
        cameraBearingAnimtaion.duration = 2.0
        cameraBearingAnimtaion.timingFunction = timeFunctionCurve
        cameraBearingAnimtaion.toValue = 0.0
        mapView.layer.add(cameraBearingAnimtaion, forKey: kGMSLayerCameraBearingKey)
           
        // flyout to the minimum zoom then zoom back to the current zoom
        let zoom = mapView.camera.zoom
        let values = [zoom, kGMSMinZoomLevel, zoom]
        let zoomAnimation = CAKeyframeAnimation(keyPath: kGMSLayerCameraZoomLevelKey)
        zoomAnimation.duration = 2.0
        zoomAnimation.values = values
        mapView.layer.add(zoomAnimation, forKey: kGMSLayerCameraZoomLevelKey)
    }
    
}

//MARK:- GMSMapViweDelegate
extension GoogleMapsController : GMSMapViewDelegate{
  
    // if  marker has a InfoWindow return NO to allow markerInfoWindow to
    // fire. Also check that the marker isn't already selected so that the
    // InfoWindow doesn't close.
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if marker.title != "indicator"{
            animateTo(marker.position)
        }
        return true
    }
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        return nil
    }
}
