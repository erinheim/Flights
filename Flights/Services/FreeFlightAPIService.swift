//
//  FlightAwareService.swift
//  Flights
//
//  Created by Erin Heim on 11/25/25.
//

import Foundation

// Using the FREE flight-data.com API - No API key required!

enum FlightAPIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case noDataFound

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noDataFound:
            return "No flight data found"
        }
    }
}

// MARK: - Response Models for flight-data.com

struct FlightDataResponse: Codable {
    let data: [FlightDataFlight]?
}

struct FlightDataFlight: Codable {
    let flightNumber: String?
    let airline: String?
    let departureAirport: String?
    let arrivalAirport: String?
    let departureTime: String?
    let arrivalTime: String?
    let status: String?
    let gate: String?
    let terminal: String?

    enum CodingKeys: String, CodingKey {
        case flightNumber = "flight_number"
        case airline
        case departureAirport = "departure_airport"
        case arrivalAirport = "arrival_airport"
        case departureTime = "departure_time"
        case arrivalTime = "arrival_time"
        case status
        case gate
        case terminal
    }
}

// MARK: - Free Flight API Service

class FreeFlightAPIService {
    private var airportCache: [String: Airport] = [:]

    // This API is completely free and requires no authentication
    private let baseURL = "https://api.aviationapi.com/v1/flights"

    func hasAPIKey() -> Bool {
        return true // Always available, no key needed
    }

    // MARK: - Flight Search

    func searchFlights(query: String) async throws -> [Flight] {
        // Search by flight number
        guard !query.isEmpty else {
            throw FlightAPIError.invalidURL
        }

        let urlString = "\(baseURL)?flight=\(query)"
        guard let url = URL(string: urlString) else {
            throw FlightAPIError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FlightAPIError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw FlightAPIError.invalidResponse
            }

            // Try to decode the response
            let decoder = JSONDecoder()

            // The API might return different formats, so we'll handle this gracefully
            if let flightArray = try? decoder.decode([FlightDataFlight].self, from: data) {
                return try await convertFlights(flightArray)
            } else if let response = try? decoder.decode(FlightDataResponse.self, from: data),
                      let flights = response.data {
                return try await convertFlights(flights)
            } else {
                // If we can't decode, return empty array (API might be down or format changed)
                return []
            }

        } catch let error as FlightAPIError {
            throw error
        } catch {
            throw FlightAPIError.networkError(error)
        }
    }

    func getFlight(flightNumber: String, date: Date? = nil) async throws -> Flight? {
        let flights = try await searchFlights(query: flightNumber)
        return flights.first
    }

    // MARK: - Conversion

    private func convertFlights(_ apiFlights: [FlightDataFlight]) async throws -> [Flight] {
        var flights: [Flight] = []

        for apiFlightData in apiFlights {
            if let flight = try await convertToFlight(apiFlightData) {
                flights.append(flight)
            }
        }

        return flights
    }

    private func convertToFlight(_ apiFlightData: FlightDataFlight) async throws -> Flight? {
        guard let flightNumber = apiFlightData.flightNumber,
              let airlineName = apiFlightData.airline,
              let depAirportCode = apiFlightData.departureAirport,
              let arrAirportCode = apiFlightData.arrivalAirport,
              let depTimeStr = apiFlightData.departureTime,
              let arrTimeStr = apiFlightData.arrivalTime else {
            return nil
        }

        // Parse dates
        let isoFormatter = ISO8601DateFormatter()
        guard let scheduledDeparture = isoFormatter.date(from: depTimeStr),
              let scheduledArrival = isoFormatter.date(from: arrTimeStr) else {
            return nil
        }

        // Get airports
        let originAirport = try await getAirport(code: depAirportCode)
        let destinationAirport = try await getAirport(code: arrAirportCode)

        // Map status
        let status = mapFlightStatus(apiFlightData.status)

        return Flight(
            flightNumber: flightNumber,
            airline: airlineName,
            origin: originAirport,
            destination: destinationAirport,
            scheduledDeparture: scheduledDeparture,
            scheduledArrival: scheduledArrival,
            status: status,
            departureGate: apiFlightData.gate,
            departureTerminal: apiFlightData.terminal
        )
    }

    private func getAirport(code: String) async throws -> Airport {
        // Check cache
        if let cachedAirport = airportCache[code] {
            return cachedAirport
        }

        // Use mock data airports if available
        if let mockAirport = MockData.airports.first(where: { $0.code == code }) {
            airportCache[code] = mockAirport
            return mockAirport
        }

        // Create basic airport
        let airport = Airport(
            code: code,
            name: "\(code) Airport",
            city: code,
            country: "Unknown",
            timezone: "UTC",
            latitude: 0.0,
            longitude: 0.0
        )

        airportCache[code] = airport
        return airport
    }

    private func mapFlightStatus(_ status: String?) -> FlightStatus {
        guard let status = status?.lowercased() else {
            return .scheduled
        }

        if status.contains("scheduled") {
            return .scheduled
        } else if status.contains("active") || status.contains("airborne") || status.contains("air") {
            return .inAir
        } else if status.contains("landed") {
            return .landed
        } else if status.contains("cancelled") {
            return .cancelled
        } else if status.contains("delayed") {
            return .delayed
        } else {
            return .scheduled
        }
    }
}
