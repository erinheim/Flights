//
//  AviationStackService.swift
//  Flights
//
//  Created by Erin Heim on 11/25/25.
//

import Foundation

enum AviationStackError: Error {
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
            return "API key not configured. Please add AVIATIONSTACK_API_KEY to Info.plist"
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

class AviationStackService {
    private let baseURL = "https://api.aviationstack.com/v1"
    private var apiKey: String?

    // Airport cache for faster lookups
    private var airportCache: [String: Airport] = [:]

    init() {
        // Try to load API key from Info.plist
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let key = dict["AVIATIONSTACK_API_KEY"] as? String,
           !key.isEmpty {
            self.apiKey = key
        }
    }

    // Set API key programmatically
    func setAPIKey(_ key: String) {
        self.apiKey = key
    }

    // MARK: - Flight Search

    func searchFlights(query: String) async throws -> [Flight] {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AviationStackError.noAPIKey
        }

        let queryItems = buildQueryItems(for: query, apiKey: apiKey)
        guard let url = urlWith(path: "/flights", items: queryItems) else { throw AviationStackError.invalidURL }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AviationStackError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw AviationStackError.apiError("HTTP \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(AviationStackFlightResponse.self, from: data)

            guard let flightsData = apiResponse.data else {
                return []
            }

            // Convert API flights to app Flight models
            var flights: [Flight] = []
            for apiFlightData in flightsData {
                if let flight = try await convertToFlight(apiFlightData) {
                    flights.append(flight)
                }
            }

            return flights
        } catch let error as AviationStackError {
            throw error
        } catch let error as DecodingError {
            throw AviationStackError.decodingError(error)
        } catch {
            throw AviationStackError.networkError(error)
        }
    }

    // MARK: - Get Flight by Flight Number

    func getFlight(flightNumber: String, date: Date? = nil) async throws -> Flight? {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AviationStackError.noAPIKey
        }

        var queryItems = [
            URLQueryItem(name: "access_key", value: apiKey),
            URLQueryItem(name: "flight_iata", value: flightNumber)
        ]
        if let date = date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            queryItems.append(URLQueryItem(name: "flight_date", value: dateFormatter.string(from: date)))
        }

        guard let url = urlWith(path: "/flights", items: queryItems) else { throw AviationStackError.invalidURL }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AviationStackError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw AviationStackError.apiError("HTTP \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(AviationStackFlightResponse.self, from: data)

            guard let flightsData = apiResponse.data, let firstFlight = flightsData.first else {
                return nil
            }

            return try await convertToFlight(firstFlight)
        } catch let error as AviationStackError {
            throw error
        } catch let error as DecodingError {
            throw AviationStackError.decodingError(error)
        } catch {
            throw AviationStackError.networkError(error)
        }
    }

    // MARK: - Helper Methods

    private func convertToFlight(_ apiFlightData: AviationStackFlight) async throws -> Flight? {
        // Get airport IATA codes
        guard let departureIATA = apiFlightData.departure.iata,
              let arrivalIATA = apiFlightData.arrival.iata else {
            return nil
        }

        // Get or fetch airport data
        let originAirport = try await getAirport(iata: departureIATA, name: apiFlightData.departure.airport)
        let destinationAirport = try await getAirport(iata: arrivalIATA, name: apiFlightData.arrival.airport)

        return apiFlightData.toFlight(originAirport: originAirport, destinationAirport: destinationAirport)
    }

    private func getAirport(iata: String, name: String?) async throws -> Airport {
        // Check cache first
        if let cachedAirport = airportCache[iata] {
            return cachedAirport
        }

        // For now, create airport with limited data
        // In a production app, you'd want to fetch full airport details from another API
        let airport = Airport(
            code: iata,
            name: name ?? iata,
            city: extractCity(from: name),
            country: "Unknown",
            timezone: "UTC",
            latitude: 0.0, // Would need airport database API
            longitude: 0.0
        )

        airportCache[iata] = airport
        return airport
    }

    private func extractCity(from airportName: String?) -> String {
        guard let name = airportName else { return "Unknown" }
        // Try to extract city from airport name (basic implementation)
        if let match = name.range(of: "^[A-Za-z\\s]+", options: .regularExpression) {
            return String(name[match]).trimmingCharacters(in: .whitespaces)
        }
        return name
    }

    // Check if API key is configured
    func hasAPIKey() -> Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }

    // MARK: - Helpers

    private func buildQueryItems(for query: String, apiKey: String) -> [URLQueryItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var items: [URLQueryItem] = [
            URLQueryItem(name: "access_key", value: apiKey),
            URLQueryItem(name: "limit", value: "20")
        ]

        // Prefer flight number queries when digits are present
        if trimmed.rangeOfCharacter(from: .decimalDigits) != nil {
            let normalizedFlight = normalizedFlightNumber(trimmed)
            items.append(URLQueryItem(name: "flight_iata", value: normalizedFlight))
            // Also send generic search as a fallback
            items.append(URLQueryItem(name: "search", value: normalizedFlight))
        } else if !trimmed.isEmpty {
            // Broader search on airline name/code and generic search
            if let inferred = inferredAirlineCode(from: trimmed) {
                items.append(URLQueryItem(name: "airline_iata", value: inferred))
            }
            items.append(URLQueryItem(name: "airline_name", value: trimmed))
            items.append(URLQueryItem(name: "search", value: trimmed))
        }

        return items
    }

    private func urlWith(path: String, items: [URLQueryItem]) -> URL? {
        var components = URLComponents(string: "\(baseURL)\(path)")
        components?.queryItems = items
        return components?.url
    }

    // Try to infer an airline IATA code from a free-form query to improve matches (e.g., "Alaska" -> "AS").
    private func inferredAirlineCode(from query: String) -> String? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let upper = trimmed.uppercased()

        // If the query looks like a 2-3 letter code, use it directly.
        if upper.count <= 3, upper.range(of: "^[A-Z]{2,3}$", options: .regularExpression) != nil {
            return upper
        }

        // Common airline name -> code mapping (extend as needed).
        let known: [String: String] = [
            "ALASKA": "AS",
            "ALASKA AIRLINES": "AS",
            "DELTA": "DL",
            "DELTA AIR LINES": "DL",
            "AMERICAN": "AA",
            "AMERICAN AIRLINES": "AA",
            "UNITED": "UA",
            "UNITED AIRLINES": "UA",
            "SOUTHWEST": "WN",
            "SOUTHWEST AIRLINES": "WN",
            "JETBLUE": "B6",
            "JETBLUE AIRWAYS": "B6"
        ]

        return known[upper]
    }

    // Normalize user-entered flight numbers:
    // - If user types an ICAO-style code (e.g., "ASA103"), convert to IATA ("AS103").
    // - Otherwise return trimmed input.
    private func normalizedFlightNumber(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // If already looks like IATA (2 letters + digits), keep as-is.
        if trimmed.range(of: "^[A-Z]{2}[0-9].*", options: .regularExpression) != nil {
            return trimmed
        }

        // If looks like ICAO (3 letters + digits), try to map prefix.
        if let match = trimmed.range(of: "^[A-Z]{3}[0-9].*", options: .regularExpression) {
            let prefix = String(trimmed.prefix(3))
            let suffix = String(trimmed.suffix(trimmed.count - 3))
            if let iata = inferredIATACode(fromICAO: prefix) {
                return iata + suffix
            }
        }

        return trimmed
    }

    private func inferredIATACode(fromICAO icao: String) -> String? {
        let map: [String: String] = [
            "ASA": "AS", // Alaska
            "DAL": "DL", // Delta
            "UAL": "UA", // United
            "AAL": "AA"  // American
        ]
        return map[icao.uppercased()]
    }
}
