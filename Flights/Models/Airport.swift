//
//  Airport.swift
//  Flights
//
//  Created by Erin Heim on 11/25/25.
//

import Foundation
import CoreLocation

struct Airport: Identifiable, Codable, Hashable {
    let id: UUID
    let code: String
    let name: String
    let city: String
    let country: String
    let timezone: String
    let latitude: Double
    let longitude: Double

    init(id: UUID = UUID(), code: String, name: String, city: String, country: String, timezone: String, latitude: Double, longitude: Double) {
        self.id = id
        self.code = code
        self.name = name
        self.city = city
        self.country = country
        self.timezone = timezone
        self.latitude = latitude
        self.longitude = longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
