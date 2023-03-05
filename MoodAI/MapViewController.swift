//
//  MapViewController.swift
//  MoodAI
//  Takato Kan

import UIKit
import GoogleMaps

class MapViewController: UIViewController {
    
    var zoom:Float = 15
    let lat = -23.562573
    let long = -46.654052
    var image: UIImage?
    var Emoji: String?

    @IBOutlet weak var zoomOutButton: UIButton!
    @IBOutlet weak var zoomInButton: UIButton!
    @IBOutlet weak var retakeButton: UIButton!
    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet var mapView: GMSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        createMapView()
        addMarker()
        addFriend1()
        addFriend2()
        zoomOutButton.layer.cornerRadius = zoomOutButton.frame.width / 2
        zoomOutButton.layer.masksToBounds = true
        
        zoomInButton.layer.cornerRadius = zoomInButton.frame.width / 2
        zoomInButton.layer.masksToBounds = true
        
        retakeButton.layer.cornerRadius = retakeButton.frame.width / 2
        retakeButton.layer.masksToBounds = true
        
        self.view.bringSubviewToFront(self.buttonsView)
        self.mapView.mapStyle(withFilename: "custom", andType: ".json")
    }
    

    func createMapView() {
        let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: long, zoom: zoom)
        mapView.camera = camera
        mapView.isMyLocationEnabled = true
        
    }
    
    func addMarker() {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(lat, long)
        marker.title = "You"
        marker.snippet = "retake your selfie!"
        marker.map = mapView
        let face = self.image?.circularImage(36, icon: 1)
        var emoji = self.Emoji?.image()
        emoji = emoji?.circularImage(15, icon: 0)
        let combined = face?.overlayWith(image: emoji!, posX: 80, posY: 0)
        marker.icon = combined
    }
    
    func addFriend1() {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(lat+0.009, long+0.005)
        marker.title = "friend 1"
        marker.snippet = "test"
        marker.map = mapView
        var prof = UIImage(systemName: "person.circle.fill")
        prof = resizeImage(image: prof!, size: 60)
        prof = prof?.circularImage(20, icon: 2)
        let emoji = "😍"
        var emo = emoji.image()
        emo = emo?.circularImage(15, icon: 0)
        let combined = prof!.overlayWith(image: emo!, posX: 50, posY: 0)
        marker.icon = combined
    }
    
    func addFriend2() {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(lat+0.005, long-0.008)
        marker.title = "friend 2"
        marker.snippet = "test"
        marker.map = mapView
        //marker.icon = UIImage(systemName: "person.circle.fill")
        var prof = UIImage(systemName: "person.circle.fill")
        prof = resizeImage(image: prof!, size: 60)
        prof = prof?.circularImage(20, icon: 3)
        let emoji = "😱"
        var emo = emoji.image()
        emo = emo?.circularImage(15, icon: 0)
        let combined = prof!.overlayWith(image: emo!, posX: 50, posY: 0)
        marker.icon = combined
    }
    
    @IBAction func zoomIn(_ sender: Any) {
        zoom = zoom + 1
        self.mapView.animate(toZoom: zoom)
    }
    
    @IBAction func zoomOut(_ sender: Any) {
        zoom = zoom - 1
        self.mapView.animate(toZoom: zoom)
    }
    
    /* do not make it available for now
    @IBAction func myLocation(_ sender: Any) {
        guard let lat = self.mapView.myLocation?.coordinate.latitude, let long = self.mapView.myLocation?.coordinate.longitude else {
            return
        }
        
        let camera = GMSCameraPosition(latitude: lat, longitude: long, zoom: zoom)
        self.mapView.animate(to: camera)
        
        let position = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let userLocation = GMSMarker(position: position)
        let face = self.image?.circularImage(36, icon: 1)
        var emoji = self.Emoji?.image()
        emoji = emoji?.circularImage(15, icon: 0)
        let combined = face?.overlayWith(image: emoji!, posX: 80, posY: 0)
        userLocation.icon = combined
        userLocation.map = mapView
    } */
    
    func resizeImage (image: UIImage, size: Int) -> UIImage? {
        
        var newsize : CGSize
        
        newsize = CGSize(width: size, height: size)
        
        
        let rect = CGRect(origin: .zero, size: newsize)
        
        UIGraphicsBeginImageContextWithOptions(newsize, false, 1.0)
            image.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return newImage
    }

}

extension GMSMapView {
    func mapStyle(withFilename name:String, andType type:String) {
        do {
            if let styleURL = Bundle.main.url(forResource: name, withExtension: type){
                self.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                NSLog("map style error")
            }
        }
        catch {
            NSLog("failed to load the map style. \(error)")
        }
    }
}

extension UIImage {
    func circularImage(_ radius: CGFloat, icon: Int) -> UIImage? {
        var imageView = UIImageView()
        if self.size.width > self.size.height {
            imageView.frame =  CGRect(x: 0, y: 0, width: self.size.width, height: self.size.width)
            imageView.image = self
            imageView.contentMode = .scaleAspectFit
        } else { imageView = UIImageView(image: self) }
        var layer: CALayer = CALayer()
    
        layer = imageView.layer
        layer.masksToBounds = true
        layer.cornerRadius = radius
        if icon == 1 {
            layer.borderWidth = 6
            layer.borderColor = UIColor.purple.cgColor
        }
        if icon == 2 {
            layer.borderWidth = 4
            layer.borderColor = UIColor.yellow.cgColor
        }
        if icon == 3 {
            layer.borderWidth = 4
            layer.borderColor = UIColor.green.cgColor
        }
        UIGraphicsBeginImageContext(imageView.bounds.size)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    
        return roundedImage
    }
    
    func overlayWith(image: UIImage, posX: CGFloat, posY: CGFloat) -> UIImage {
      let newWidth = size.width < posX + image.size.width ? posX + image.size.width : size.width
      let newHeight = size.height < posY + image.size.height ? posY + image.size.height : size.height
      let newSize = CGSize(width: newWidth, height: newHeight)

      UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
      draw(in: CGRect(origin: CGPoint.zero, size: size))
      image.draw(in: CGRect(origin: CGPoint(x: posX, y: posY), size: image.size))
      let newImage = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()

      return newImage
    }
}

extension String {
    func image() -> UIImage? {
        let size = CGSize(width: 30, height: 30)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.white.set()
        let rect = CGRect(origin: .zero, size: size)
        UIRectFill(CGRect(origin: .zero, size: size))
        (self as AnyObject).draw(in: rect, withAttributes: [.font: UIFont.systemFont(ofSize: 30)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
