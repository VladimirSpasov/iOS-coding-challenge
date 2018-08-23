//
//  OpenWeatherModels.swift
//  Talking Weather
//
//  Created by SPASOV DIMITROV Vladimir on 21/8/18.
//  Copyright © 2018 SPASOV DIMITROV Vladimir. All rights reserved.
//

struct OpenWeatherResponse: Codable {
    let coord: Coord
    let weather: [Weather]
    let base: String
    let main: Main
    let wind: Wind
    let clouds: Clouds
    let dt: Int
    let sys: Sys
    let id: Int
    let name: String
    let cod: Int
}

struct Clouds: Codable {
    let all: Int
}

struct Coord: Codable {
    let lon, lat: Double
}

struct Main: Codable {
    let temp, pressure: Double
    let humidity: Int
    let tempMin: Double
    let tempMax: Double
    let seaLevel: Double?
    let grndLevel: Double?
    
    enum CodingKeys: String, CodingKey {
        case temp, pressure, humidity
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case seaLevel = "sea_level"
        case grndLevel = "grnd_level"
    }
}

struct Sys: Codable {
    let message: Double
    let country: String
    let sunrise: Int
    let sunset: Int
}

struct Weather: Codable {
    let id: Int
    let main, description, icon: String
}

struct Wind: Codable {
    let speed: Double
    let deg: Int
}
