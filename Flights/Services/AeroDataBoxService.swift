//
//  AeroDataBoxService.swift
//  Flights
//
//  Created by Erin Heim on 11/25/25.
//

import Foundation

enum AeroDataBoxError: Error {
    case invalidURL
    case noAPIKey
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case apiError(String)

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noAPIKey:
            return "API key not configured. Please add RAPIDAPI_KEY to Info.plist"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

// MARK: - API Response Models

struct AeroDataBoxFlight: Codable {
    let number: String?
    let airline: AeroDataBoxAirline?
    let departure: AeroDataBoxFlightLeg?
    let arrival: AeroDataBoxFlightLeg?
    let status: String?
    let aircraft: AeroDataBoxAircraft?
}

struct AeroDataBoxAirline: Codable {
    let name: String?
}

struct AeroDataBoxFlightLeg: Codable {
    let airport: AeroDataBoxAirport?
    let scheduledTime: AeroDataBoxTime?
    let actualTime: AeroDataBoxTime?
    let terminal: String?
    let gate: String?
    let baggageBelt: String?
    let quality: [String]?
}

struct AeroDataBoxAirport: Codable {
    let iata: String?
    let icao: String?
    let name: String?
    let location: AeroDataBoxLocation?
}

struct AeroDataBoxLocation: Codable {
    let lat: Double?
    let lon: Double?
}

struct AeroDataBoxTime: Codable {
    let local: String?
    let utc: String?
}

struct AeroDataBoxAircraft: Codable {
    let model: String?
    let reg: String?
}

// MARK: - Service

class AeroDataBoxService {
    private let baseURL = "https://aerodatabox.p.rapidapi.com"
    private var apiKey: String?
    private var airportCache: [String: Airport] = [:]

    init() {
        // Try to load API key from Info.plist
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let key = dict["RAPIDAPI_KEY"] as? String,
           !key.isEmpty {
            self.apiKey = key
        }
    }

    func setAPIKey(_ key: String) {
        self.apiKey = key
    }

    func hasAPIKey() -> Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }

    // MARK: - Flight Search

    func searchFlights(query: String) async throws -> [Flight] {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AeroDataBoxError.noAPIKey
        }

        // For AeroDataBox, we'll search by flight number
        // Format: AA100 or UA555
        return try await searchByFlightNumber(query)
    }

    private func searchByFlightNumber(_ flightNumber: String) async throws -> [Flight] {
        guard let apiKey = apiKey else {
            throw AeroDataBoxError.noAPIKey
        }

        // Get today's date in required format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())

        // Build URL
        let urlString = "\(baseURL)/flights/number/\(flightNumber)/\(today)"
        guard let url = URL(string: urlString) else {
            throw AeroDataBoxError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.addValue("aerodatabox.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AeroDataBoxError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw AeroDataBoxError.apiError("HTTP \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            let apiFlights = try decoder.decode([AeroDataBoxFlight].self, from: data)

            var flights: [Flight] = []
            for apiFlightData in apiFlights {
                if let flight = try await convertToFlight(apiFlightData) {
                    flights.append(flight)
                }
            }

            return flights
        } catch let error as AeroDataBoxError {
            throw error
        } catch let error as DecodingError {
            throw AeroDataBoxError.decodingError(error)
        } catch {
            throw AeroDataBoxError.networkError(error)
        }
    }

    func getFlight(flightNumber: String, date: Date? = nil) async throws -> Flight? {
        let flights = try await searchFlights(query: flightNumber)
        return flights.first
    }

    // MARK: - Conversion

    private func convertToFlight(_ apiFlightData: AeroDataBoxFlight) async throws -> Flight? {
        guard let flightNumber = apiFlightData.number,
              let airlineName = apiFlightData.airline?.name,
              let departureAirportData = apiFlightData.departure?.airport,
              let arrivalAirportData = apiFlightData.arrival?.airport,
              let scheduledDepStr = apiFlightData.departure?.scheduledTime?.utc,
              let scheduledArrStr = apiFlightData.arrival?.scheduledTime?.utc else {
            return nil
        }

        // Parse dates
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard var scheduledDeparture = isoFormatter.date(from: scheduledDepStr),
              var scheduledArrival = isoFormatter.date(from: scheduledArrStr) else {
            // Try without fractional seconds
            isoFormatter.formatOptions = [.withInternetDateTime]
            guard let scheduledDeparture = isoFormatter.date(from: scheduledDepStr),
                  let scheduledArrival = isoFormatter.date(from: scheduledArrStr) else {
                return nil
            }
            return try await createFlight(
                flightNumber: flightNumber,
                airlineName: airlineName,
                apiFlightData: apiFlightData,
                departureAirportData: departureAirportData,
                arrivalAirportData: arrivalAirportData,
                scheduledDeparture: scheduledDeparture,
                scheduledArrival: scheduledArrival,
                isoFormatter: isoFormatter
            )
        }

        return try await createFlight(
            flightNumber: flightNumber,
            airlineName: airlineName,
            apiFlightData: apiFlightData,
            departureAirportData: departureAirportData,
            arrivalAirportData: arrivalAirportData,
            scheduledDeparture: scheduledDeparture,
            scheduledArrival: scheduledArrival,
            isoFormatter: isoFormatter
        )
    }

    private func createFlight(
        flightNumber: String,
        airlineName: String,
        apiFlightData: AeroDataBoxFlight,
        departureAirportData: AeroDataBoxAirport,
        arrivalAirportData: AeroDataBoxAirport,
        scheduledDeparture: Date,
        scheduledArrival: Date,
        isoFormatter: ISO8601DateFormatter
    ) async throws -> Flight {
        // Get airports
        let originAirport = try await getAirport(from: departureAirportData)
        let destinationAirport = try await getAirport(from: arrivalAirportData)

        // Parse actual times
        let actualDeparture = apiFlightData.departure?.actualTime?.utc.flatMap { isoFormatter.date(from: $0) }
        let actualArrival = apiFlightData.arrival?.actualTime?.utc.flatMap { isoFormatter.date(from: $0) }

        // Calculate delay
        var delayMinutes: Int?
        if let actualDep = actualDeparture {
            delayMinutes = Int(actualDep.timeIntervalSince(scheduledDeparture) / 60)
        }

        // Map status
        let status = mapFlightStatus(apiFlightData.status)

        // Get aircraft info
        let aircraftType = apiFlightData.aircraft?.model

        return Flight(
            flightNumber: flightNumber,
            airline: airlineName,
            origin: originAirport,
            destination: destinationAirport,
            scheduledDeparture: scheduledDeparture,
            scheduledArrival: scheduledArrival,
            actualDeparture: actualDeparture,
            actualArrival: actualArrival,
            status: status,
            departureGate: apiFlightData.departure?.gate,
            departureTerminal: apiFlightData.departure?.terminal,
            arrivalGate: apiFlightData.arrival?.gate,
            arrivalTerminal: apiFlightData.arrival?.terminal,
            baggageClaim: apiFlightData.arrival?.baggageBelt,
            aircraft: aircraftType,
            delay: delayMinutes
        )
    }

    private func getAirport(from airportData: AeroDataBoxAirport) async throws -> Airport {
        guard let iata = airportData.iata else {
            throw AeroDataBoxError.apiError("Missing airport IATA code")
        }

        // Check cache
        if let cachedAirport = airportCache[iata] {
            return cachedAirport
        }

        let airport = Airport(
            code: iata,
            name: airportData.name ?? iata,
            city: extractCity(from: airportData.name),
            country: "Unknown",
            timezone: "UTC",
            latitude: airportData.location?.lat ?? 0.0,
            longitude: airportData.location?.lon ?? 0.0
        )

        airportCache[iata] = airport
        return airport
    }

    private func extractCity(from airportName: String?) -> String {
        guard let name = airportName else { return "Unknown" }
        // Try to extract city from airport name
        if let match = name.range(of: "^[A-Za-z\\s]+", options: .regularExpression) {
            return String(name[match]).trimmingCharacters(in: .whitespaces)
        }
        return name
    }

    private func mapFlightStatus(_ status: String?) -> FlightStatus {
        guard let status = status?.lowercased() else {
            return .scheduled
        }

        if status.contains("scheduled") {
            return .scheduled
        } else if status.contains("active") || status.contains("airborne") {
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
