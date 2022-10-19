//
//  LocationManager.swift
//  DontCrossTheLine
//
//  Created by Mary Moreira on 19/10/2022.
//

import Foundation
import CoreLocation
import UserNotifications
import UIKit
import Combine

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    static let shared = LocationManager()
    @Published var location: CLLocation?
    let manager = CLLocationManager()
    @Published var isToShowAlert: Bool = false
    
    
    func setupLocationManager() {
        manager.requestAlwaysAuthorization()
        manager.allowsBackgroundLocationUpdates = true
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        manager.startUpdatingLocation()
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        if self.location == nil {
            self.location = location
        } else if self.location?.distance(from: location) ?? 0 > 50 {
            if UIApplication.shared.applicationState == .background {
                createLocalNotification()
            } else {
               isToShowAlert = true
            }
        }
    }
    
    func createLocalNotification() {
        //creating the notification content
          let content = UNMutableNotificationContent()
          
          //adding title, subtitle, body and badge
          content.title = "You are getting out of limit"
          content.subtitle = ""
          content.body = "Please come back or police will show up."
          content.badge = 1
          content.sound = .defaultCritical
          
          //getting the notification trigger
          //it will be called after 5 seconds
          let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
          
          //getting the notification request
          let request = UNNotificationRequest(identifier: "SimplifiedIOSNotification", content: content, trigger: trigger)
                  
          //adding the notification to notification center
          UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
