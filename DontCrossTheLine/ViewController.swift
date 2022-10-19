//
//  ViewController.swift
//  DontCrossTheLine
//
//  Created by Mary Moreira on 18/10/2022.
//

import UIKit
import MapKit
import UserNotifications
import Combine

class ViewController: UIViewController, MKMapViewDelegate {
    
    private lazy var container: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var image: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    
    private lazy var button: UIButton = {
        let button = UIButton()
        button.setTitle("STOP Alerts!", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.backgroundColor = .red
        button.layer.cornerRadius = 5
        button.isUserInteractionEnabled = true
        button.addTarget(self, action: #selector(removeAlerts), for: .touchUpInside)
        return button
    }()

    private let map: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    var cancelAlerts: Bool = false
    
    private var subscriber: AnyCancellable?
    private var subscriberToLocation: AnyCancellable?
    private var subscribeToButton: AnyCancellable?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        LocationManager.shared.setupLocationManager()
        subscriber = LocationManager.shared.$isToShowAlert.sink(receiveValue: { [weak self] value in
            if value {
                DispatchQueue.main.async {
                    self?.showAlert()
                    self?.updateTextAndColor(danger: value)
                }
            }
        })
        subscriberToLocation = LocationManager.shared.$location.sink(receiveValue: { [weak self] location in
            guard let locationValue = location else { return }
            self?.createPin(location: locationValue)
        })
        setupUI()
       
    }
    
    func updateTextAndColor(danger: Bool) {
        titleLabel.text = danger ? "POLICE WILL AREST YOU! 🚔": "This map will help you stay out of jail 🕊"
        titleLabel.textColor = danger ? .red : .black
        image.image = UIImage(named: danger ? "jail" : "free")

    }
    
    func setupUI() {
        view.addSubview(container)
        container.fillSuperview()
        
        container.addSubview(button)
        button.anchor(left: container.leftAnchor, bottom: container.bottomAnchor, right: container.rightAnchor, paddingLeft: 20, paddingBottom: 40, paddingRight: 20, height: 50)
        
        container.addSubview(map)
        view.addSubview(map)
        map.anchor(top: container.topAnchor, left: container.leftAnchor, bottom: button.bottomAnchor, right: container.rightAnchor, paddingTop: 200, paddingLeft: 20, paddingBottom: 60, paddingRight: 20)
        map.layer.cornerRadius = 10
        
        container.addSubview(image)
        image.anchor(left: container.leftAnchor, bottom: map.topAnchor, right: container.rightAnchor, paddingTop: 10, paddingLeft: 20, paddingBottom: 30, paddingRight: 20)
        image.setDimensions(height: 60, width: 60)

        
        container.addSubview(titleLabel)
        titleLabel.anchor(top: container.topAnchor, left: container.leftAnchor, bottom: image.topAnchor, right: container.rightAnchor, paddingTop: 40, paddingLeft: 20, paddingRight: 20)
    

        map.delegate = self
        map.showsUserLocation = true
        map.userTrackingMode = .follow
        requestNotification()
        updateTextAndColor(danger: false)
    }
    
    func createPin(location: CLLocation) {
        let pin = MKPointAnnotation()
        pin.coordinate = location.coordinate
        self.map.setRegion(MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)), animated: true)
        pin.title = "Freedom"
        self.map.addAnnotation(pin)
        let regionRadius = 50.0
        let circle = MKCircle(center: location.coordinate, radius: regionRadius)
        self.map.addOverlay(circle)
    }
    
    func showAlert() {
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "You have reached the limit", message: "Please come back or police will pick you up", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Reset Location", style: UIAlertAction.Style.destructive, handler: { [weak self]_ in
                guard let mapAnnotations = self?.map.annotations, let overlay = self?.map.overlays.first else { return }
                self?.map.removeAnnotations(mapAnnotations)
                self?.map.removeOverlay(overlay)
                LocationManager.shared.location = nil
                LocationManager.shared.manager.requestLocation()
                self?.updateTextAndColor(danger: false)
            }))
            alert.addAction(UIAlertAction(title: "I will go back", style: UIAlertAction.Style.default, handler: { [weak self]_ in
                self?.updateTextAndColor(danger: false)
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func requestNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: { didAllow, error in
            
        })
    }
    
    @objc func removeAlerts() {
        cancelAlerts.toggle()
        if cancelAlerts {
            LocationManager.shared.manager.stopUpdatingLocation()
        } else {
            LocationManager.shared.manager.startUpdatingLocation()
        }
        button.backgroundColor = cancelAlerts ? .systemIndigo : .red
        button.setTitle(cancelAlerts ? "Reativate Alerts" : "STOP Alerts!", for: .normal)
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.strokeColor = UIColor.red
            circleRenderer.lineWidth = 3.0
            return circleRenderer
        }
        else {
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}




extension UIView {
    func anchor(top: NSLayoutYAxisAnchor? = nil,
                left: NSLayoutXAxisAnchor? = nil,
                bottom: NSLayoutYAxisAnchor? = nil,
                right: NSLayoutXAxisAnchor? = nil,
                paddingTop: CGFloat = 0,
                paddingLeft: CGFloat = 0,
                paddingBottom: CGFloat = 0,
                paddingRight: CGFloat = 0,
                width: CGFloat? = nil,
                height: CGFloat? = nil) {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
        }
        
        if let left = left {
            leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }
        
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
        }
        
        if let right = right {
            rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
        }
        
        if let width = width {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        
        if let height = height {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
    
    func center(inView view: UIView, yConstant: CGFloat? = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: yConstant!).isActive = true
    }
    
    func centerX(inView view: UIView, topAnchor: NSLayoutYAxisAnchor? = nil, paddingTop: CGFloat? = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        if let topAnchor = topAnchor {
            self.topAnchor.constraint(equalTo: topAnchor, constant: paddingTop!).isActive = true
        }
    }
    
    func centerY(inView view: UIView, leftAnchor: NSLayoutXAxisAnchor? = nil,
                 paddingLeft: CGFloat = 0, constant: CGFloat = 0) {
        
        translatesAutoresizingMaskIntoConstraints = false
        centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: constant).isActive = true
        
        if let left = leftAnchor {
            anchor(left: left, paddingLeft: paddingLeft)
        }
    }
    
    func setDimensions(height: CGFloat, width: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: height).isActive = true
        widthAnchor.constraint(equalToConstant: width).isActive = true
    }
    
    func setHeight(_ height: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: height).isActive = true
    }
    
    func setWidth(_ width: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: width).isActive = true
    }
    
    func fillSuperview() {
        translatesAutoresizingMaskIntoConstraints = false
        guard let view = superview else { return }
        anchor(top: view.topAnchor, left: view.leftAnchor,
               bottom: view.bottomAnchor, right: view.rightAnchor)
    }
}
