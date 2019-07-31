//
//  ViewController.swift
//  PerfectBnbApp
//
//  Created by User on 2019-05-22.
//  Copyright © 2019 User. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import SQLite3

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    @IBOutlet weak var LocationButton: UIButton!
    @IBOutlet weak var Status: UILabel!
    var count = 0
    var db: OpaquePointer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.locationManager.requestAlwaysAuthorization()
        
        self.locationManager.requestWhenInUseAuthorization()
        
       navigationItem.backBarButtonItem = UIBarButtonItem()
        
        databaseClient()
        
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // get Lat and Long
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
    
        
        let defaults = UserDefaults.standard
    
        let lat:String = String(format:"%f", locValue.latitude)
        let long:String = String(format:"%f", locValue.longitude)
    
        // set data to local storage
        defaults.set(lat, forKey: "PerfectLat")
        defaults.set(long, forKey: "PerfectLong")
        
        print("Initial latitude: \(locValue.latitude) , Initial Longitude: \(locValue.longitude)")
        
        if(count == 0){
            insertIntoDatabase(lat: locValue.latitude,long: locValue.longitude)
        }
        else{
            updateDatabase(lat: locValue.latitude,long: locValue.longitude)
        }
        
        // change button title
        LocationButton.setTitle("Start Search", for: .normal)
        self.Status.alpha = 1
        
    }
    
    func databaseClient(){
        // setting up database
        let fileUrl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("locationDatabase.sqlite")
        
        if sqlite3_open(fileUrl.path, &db) != SQLITE_OK{
            print("Error opening database")
            return
        }
        
        let createTableQuery = "CREATE TABLE IF NOT EXISTS PerfectBnB (id INTEGER PRIMARY KEY AUTOINCREMENT, Latitude DOUBLE, Longitude DOUBLE)"
        
        if sqlite3_exec(db, createTableQuery, nil , nil, nil) != SQLITE_OK{
            print("error creating table")
            return
        }
        retriveFromDatabase()
        
    }
   
    func retriveFromDatabase(){
        // retrive data from database
        var queryStatement: OpaquePointer? = nil
        
        let queryStatementString = "SELECT * FROM PerfectBnB;"
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            
            while (sqlite3_step(queryStatement) == SQLITE_ROW) {
                let id = sqlite3_column_int(queryStatement, 0)
                let queryResultCol1 = sqlite3_column_double(queryStatement, 1)
                let queryResultCol2 = sqlite3_column_double(queryStatement, 2)
                let latitude = Double(queryResultCol1)
                let longitude = Double(queryResultCol2)
                print("Query Result:")
                print("\(id) | \(latitude) | \(longitude)")
                
                count = count + 1
            }
            
            print("database hase \(count) rows")
            
        } else {
            print("SELECT statement could not be prepared")
        }
    }
    
    func insertIntoDatabase( lat: Double,  long:Double){
        // insert data into database
        var stmt: OpaquePointer?
        
        let insertQuery = "INSERT INTO PerfectBnB (Latitude, Longitude) VALUES (?,?)"
        
        if sqlite3_prepare(db, insertQuery, -1, &stmt, nil) != SQLITE_OK{
            print("error binding query")
        }
        
        if sqlite3_bind_double(stmt, 1, lat) != SQLITE_OK{
            print("Error binding name")
        }
        
        if sqlite3_bind_double(stmt, 2, long) != SQLITE_OK{
            print("Error binding name")
        }
        
        if sqlite3_step(stmt) == SQLITE_DONE {
            print("data saved sucessfully")
            count = 1
        }
        else{
            print("erroorrrrrrrrrrrrrrrr")
        }

    }
    func updateDatabase(lat: Double, long: Double){
        // update data from database
        let updateStatementString = "UPDATE PerfectBnB SET Latitude = '\(lat)', Longitude = '\(long)' WHERE Id = 1;"
        
        var updateStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("Successfully updated row.")
            } else {
                print("Could not update row.")
            }
        } else {
            print("UPDATE statement could not be prepared")
        }
    }
    
    
    
    @IBAction func DetectMyLocationBtn(_ sender: UIButton) {
        // get button title
        let buttonTitle = LocationButton.title(for: .normal)
        if(buttonTitle == "Start Search"){
           performSegue(withIdentifier: "goToCity", sender: nil)
            
        }
        else{
            // check if location service is enabled
            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.startUpdatingLocation()
            }
            else {
                // create the alert
                let alert = UIAlertController(title: "GPS is disable", message: "Please on Location Services to continue", preferredStyle: UIAlertController.Style.alert)
                
                // add an action (button)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                
                // show the alert
                self.present(alert, animated: true, completion: nil)
            }
            
        }
        
    }
    
}

