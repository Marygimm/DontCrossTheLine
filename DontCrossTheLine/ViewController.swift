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

class ViewController: UIViewController {
    
    //MARK: - Properties
    
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

    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        LocationManager.shared.setupLocationManager()
        createSubscribers()
        setupUI()
       
    }
    
    //MARK: - Update UI

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
    
    
    func updateTextAndColor(danger: Bool) {
        titleLabel.text = danger ? "POLICE WILL AREST YOU! 🚔": "This map will help you stay out of jail 🕊"
        titleLabel.textColor = danger ? .red : .black
        image.image = UIImage(named: danger ? "jail" : "free")

    }
    
    //MARK: - Listeners
    
    func createSubscribers() {
        subscriber = LocationManager.shared.$isToShowAlert.sink(receiveValue: { [weak self] isToShowAlert in
            if isToShowAlert {
                DispatchQueue.main.async {
                    self?.showAlert(title: "You have reached the limit", message: "Please come back or police will pick you up")
                    self?.updateTextAndColor(danger: isToShowAlert)
                }
            }
        })
        subscriberToLocation = LocationManager.shared.$location.sink(receiveValue: { [weak self] location in
            guard let locationValue = location else { return }
            self?.createPin(location: locationValue)
        })
    }
    
    //MARK: - Actions
    
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
    
    func showAlert(title: String, message: String, action: UIAlertAction? = nil ) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            if let actions = action {
                alert.addAction(actions)
            } else {
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
            }
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func requestNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: { [weak self] didAllow, _ in
            guard !didAllow else { return }
            self?.showAlert(title: "Allow Notifications", message: "Will not be able to notify you in the Background", action: UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
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
    

}

extension ViewController: MKMapViewDelegate {
    
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
