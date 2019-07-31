//
//  Search.swift
//  PerfectBnbApp
//
//  Created by user on 2019-05-23.
//  Copyright © 2019 User. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreLocation
import SQLite3

class Search: UIViewController {
    
    @IBOutlet weak var cityName: UILabel!
    @IBOutlet weak var currentTemp: UILabel!
    var count = 0
    var db: OpaquePointer?
    var Lat: Double = 0.0
    var Long: Double = 0.0
    
    override func viewDidLoad() {
        
        databaseClient()
        
        if(count > 0){
            fetchDataFromURL()
        }
        
        
        
    }
    
    func fetchDataFromURL(){
        var city = ""
        var URL = ""
        // convert Lat Long to City Name
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: Lat, longitude: Long)
        geoCoder.reverseGeocodeLocation(location, completionHandler:
            {
                placemarks, error -> Void in
                
                // Place details
                guard let placeMark = placemarks?.first else { return }
                
                // City
                city = placeMark.locality!
                self.cityName.text = city
                
                URL = "https://api.worldweatheronline.com/premium/v1/weather.ashx?key=5fd6948d386843ccab3210846192305&q=\(city)&format=json&num_of_days=1"
                
                print(URL)
                Alamofire.request(URL).responseJSON {
                    response in
                    
                    // 2. get the data out of the variable
                    guard let apiData = response.result.value else {
                        print("Error getting data from the URL")
                        return
                    }
                    
                    // OUTPUT the entire json response to the terminal
                    
                    
                    let jsonResponse = JSON(apiData)
                    //let dataDictionary = jsonResponse["data"].array
                    
                    
                    let dataDictionary = jsonResponse["data"]
                    
                    let current_condition = dataDictionary["current_condition"]
                    
                    current_condition.array?.forEach({
                        (CT) in
                        let temp = CT["temp_C"].stringValue
                        self.currentTemp.text = temp
                    })
                    
                }
                
        })
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
                
                Lat = Double(queryResultCol1)
                Long = Double(queryResultCol2)
                print("Query Result:")
                print("\(id) | \(Lat) | \(Long)")
                
                count = count + 1
            }
            
            print("database hase \(count) rows")
            
        } else {
            print("SELECT statement could not be prepared")
        }
    }
}
