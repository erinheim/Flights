//
//  OpenSkyNetworkService.swift
//  Flights
//
//  Created by Erin Heim on 11/25/25.
//

import Foundation

// OpenSky Network - FREE, no API key required
// Provides real-time flight tracking data

struct OpenSkyStateVector: Codable {
    let icao24: String
    let callsign: String?
    let originCountry: String
    let timePosition: Int?
    let lastContact: Int
    let longitude: Double?
    let latitude: Double?
    let baroAltitude: Double?
    let onGround: Bool
    let velocity: Double?
    let trueTrack: Double?
    let verticalRate: Double?

    enum CodingKeys: String, CodingKey {
        case icao24 = "0"
        case callsign = "1"
        case originCountry = "2"
        case timePosition = "3"
        case lastContact = "4"
        case longitude = "5"
        case latitude = "6"
        case baroAltitude = "7"
        case onGround = "8"
        case velocity = "9"
        case trueTrack = "10"
        case verticalRate = "11"
    }
}

struct OpenSkyResponse: Codable {
    let time: Int
    let states: [[AnyCodable]]?
}

// Helper for decoding mixed-type arrays
struct AnyCodable: Codable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else {
            try container.encodeNil()
        }
    }
}

class OpenSkyNetworkService {
    private let baseURL = "https://opensky-network.org/api"
    private var airportCache: [String: Airport] = [:]

    func hasAPIKey() -> Bool {
        return true // No API key needed!
    }

    // Search for flights - OpenSky provides real-time aircraft positions
    func searchFlights(query: String) async throws -> [Flight] {
        // For now, return empty - OpenSky is better for real-time tracking than searching specific flights
        // We'll need to use a different approach or API for flight number search
        return []
    }

    func getFlight(flightNumber: String, date: Date? = nil) async throws -> Flight? {
        // OpenSky doesn't support direct flight number lookup easily
        return nil
    }

    // Get all flights in the air right now (this actually works!)
    func getLiveFlights() async throws -> [Flight] {
        let urlString = "\(baseURL)/states/all"
        guard let url = URL(string: urlString) else {
            throw FlightAPIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FlightAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw FlightAPIError.invalidResponse
        }

        let decoder = JSONDecoder()
        let openSkyResponse = try decoder.decode(OpenSkyResponse.self, from: data)

        // Convert OpenSky data to flights
        var flights: [Flight] = []

        if let states = openSkyResponse.states {
            for state in states.prefix(20) { // Limit to 20 flights
                if let flight = try await convertStateToFlight(state) {
                    flights.append(flight)
                }
            }
        }

        return flights
    }

    private func convertStateToFlight(_ state: [AnyCodable]) async throws -> Flight? {
        guard state.count >= 12 else { return nil }

        // Extract values
        guard let callsign = state[1].value as? String,
              !callsign.trimmingCharacters(in: .whitespaces).isEmpty,
              let lat = state[6].value as? Double,
              let lon = state[5].value as? Double else {
            return nil
        }

        let cleanCallsign = callsign.trimmingCharacters(in: .whitespaces)
        let onGround = state[8].value as? Bool ?? false

        // Skip if on ground
        guard !onGround else { return nil }

        // Create dummy airports based on current position
        let currentAirport = Airport(
            code: "---",
            name: "Unknown",
            city: "In Flight",
            country: "Unknown",
            timezone: "UTC",
            latitude: lat,
            longitude: lon
        )

        let destinationAirport = Airport(
            code: "???",
            name: "Unknown Destination",
            city: "Unknown",
            country: "Unknown",
            timezone: "UTC",
            latitude: lat + 5.0, // Approximate destination
            longitude: lon + 5.0
        )

        let now = Date()

        return Flight(
            flightNumber: cleanCallsign,
            airline: "Unknown",
            origin: currentAirport,
            destination: destinationAirport,
            scheduledDeparture: now.addingTimeInterval(-3600),
            scheduledArrival: now.addingTimeInterval(3600),
            status: .inAir
        )
    }
}
