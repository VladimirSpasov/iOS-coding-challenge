//
//  OpenWeatherMapClient.swift
//  Talking Weather
//
//  Created by SPASOV DIMITROV Vladimir on 21/8/18.
//  Copyright © 2018 SPASOV DIMITROV Vladimir. All rights reserved.
//


import Alamofire
import CodableAlamofire

class OpenWeatherMapClient {
    
    static let shared = OpenWeatherMapClient()
    
    let baseUrl = "https://api.openweathermap.org/data/2.5/weather"
    let APIID = "YOUR_OPEN_WETHER_MAP_APPID_HERE"
    
    func getWeather(latitude: Double, longitude: Double, completion:@escaping (Result<OpenWeatherResponse>)->Void) {
        
        let url = "\(baseUrl)?lat=\(latitude)&lon=\(longitude)&units=metric&APPID=\(APIID)"
        let decoder = JSONDecoder()
        
        Alamofire.request(url).responseDecodableObject(keyPath: nil, decoder: decoder) { (response: DataResponse<OpenWeatherResponse>) in
            completion(response.result)
        }
    }
    
}




