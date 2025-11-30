//
//  AviationStackModels.swift
//  Flights
//
//  Created by Erin Heim on 11/25/25.
//

import Foundation

// MARK: - API Response Models

struct AviationStackFlightResponse: Codable {
    let data: [AviationStackFlight]?
    let pagination: Pagination?
}

struct Pagination: Codable {
    let limit: Int
    let offset: Int
    let count: Int
    let total: Int
}

struct AviationStackFlight: Codable {
    let flightDate: String
    let flightStatus: String
    let departure: AviationStackAirportInfo
    let arrival: AviationStackAirportInfo
    let airline: AviationStackAirline
    let flight: AviationStackFlightInfo
    let aircraft: AviationStackAircraft?
    let live: AviationStackLive?

    enum CodingKeys: String, CodingKey {
        case flightDate = "flight_date"
        case flightStatus = "flight_status"
        case departure, arrival, airline, flight, aircraft, live
    }
}

struct AviationStackAirportInfo: Codable {
    let airport: String?
    let timezone: String?
    let iata: String?
    let icao: String?
    let terminal: String?
    let gate: String?
    let delay: Int?
    let scheduled: String?
    let estimated: String?
    let actual: String?
    let estimatedRunway: String?
    let actualRunway: String?
    let baggage: String?

    enum CodingKeys: String, CodingKey {
        case airport, timezone, iata, icao, terminal, gate, delay, scheduled, estimated, actual
        case estimatedRunway = "estimated_runway"
        case actualRunway = "actual_runway"
        case baggage
    }
}

struct AviationStackAirline: Codable {
    let name: String?
    let iata: String?
    let icao: String?
}

struct AviationStackFlightInfo: Codable {
    let number: String?
    let iata: String?
    let icao: String?
    let codeshared: CodesharedFlight?
}

struct CodesharedFlight: Codable {
    let airlineName: String?
    let airlineIata: String?
    let airlineIcao: String?
    let flightNumber: String?
    let flightIata: String?
    let flightIcao: String?

    enum CodingKeys: String, CodingKey {
        case airlineName = "airline_name"
        case airlineIata = "airline_iata"
        case airlineIcao = "airline_icao"
        case flightNumber = "flight_number"
        case flightIata = "flight_iata"
        case flightIcao = "flight_icao"
    }
}

struct AviationStackAircraft: Codable {
    let registration: String?
    let iata: String?
    let icao: String?
    let icao24: String?
}

struct AviationStackLive: Codable {
    let updated: String?
    let latitude: Double?
    let longitude: Double?
    let altitude: Double?
    let direction: Double?
    let speedHorizontal: Double?
    let speedVertical: Double?
    let isGround: Bool?

    enum CodingKeys: String, CodingKey {
        case updated, latitude, longitude, altitude, direction
        case speedHorizontal = "speed_horizontal"
        case speedVertical = "speed_vertical"
        case isGround = "is_ground"
    }
}

// MARK: - Conversion to App Models

extension AviationStackFlight {
    func toFlight(originAirport: Airport, destinationAirport: Airport) -> Flight? {
        guard let flightNumber = flight.iata ?? flight.number,
              let airlineName = airline.name,
              let scheduledDepartureStr = departure.scheduled,
              let scheduledArrivalStr = arrival.scheduled else {
            return nil
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let scheduledDeparture = dateFormatter.date(from: scheduledDepartureStr),
              let scheduledArrival = dateFormatter.date(from: scheduledArrivalStr) else {
            // Try without fractional seconds
            dateFormatter.formatOptions = [.withInternetDateTime]
            guard let scheduledDeparture = dateFormatter.date(from: scheduledDepartureStr),
                  let scheduledArrival = dateFormatter.date(from: scheduledArrivalStr) else {
                return nil
            }

            return createFlight(
                flightNumber: flightNumber,
                airlineName: airlineName,
                originAirport: originAirport,
                destinationAirport: destinationAirport,
                scheduledDeparture: scheduledDeparture,
                scheduledArrival: scheduledArrival,
                dateFormatter: dateFormatter
            )
        }

        return createFlight(
            flightNumber: flightNumber,
            airlineName: airlineName,
            originAirport: originAirport,
            destinationAirport: destinationAirport,
            scheduledDeparture: scheduledDeparture,
            scheduledArrival: scheduledArrival,
            dateFormatter: dateFormatter
        )
    }

    private func createFlight(
        flightNumber: String,
        airlineName: String,
        originAirport: Airport,
        destinationAirport: Airport,
        scheduledDeparture: Date,
        scheduledArrival: Date,
        dateFormatter: ISO8601DateFormatter
    ) -> Flight {
        let actualDeparture = departure.actual.flatMap { dateFormatter.date(from: $0) }
        let actualArrival = arrival.actual.flatMap { dateFormatter.date(from: $0) }

        let status = mapFlightStatus(flightStatus)
        let delayMinutes = departure.delay ?? arrival.delay

        // Get aircraft type name if available
        let aircraftType = aircraft?.iata ?? aircraft?.icao

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
            departureGate: departure.gate,
            departureTerminal: departure.terminal,
            arrivalGate: arrival.gate,
            arrivalTerminal: arrival.terminal,
            baggageClaim: arrival.baggage,
            aircraft: aircraftType,
            delay: delayMinutes
        )
    }

    private func mapFlightStatus(_ status: String) -> FlightStatus {
        switch status.lowercased() {
        case "scheduled":
            return .scheduled
        case "active", "en-route":
            return .inAir
        case "landed":
            return .landed
        case "cancelled":
            return .cancelled
        case "incident", "diverted":
            return .cancelled
        default:
            return .scheduled
        }
    }
}
