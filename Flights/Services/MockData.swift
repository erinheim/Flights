//
//  MockData.swift
//  Flights
//
//  Created by Erin Heim on 11/25/25.
//

import Foundation

struct MockData {
    static let airports: [Airport] = [
        Airport(code: "JFK", name: "John F. Kennedy International Airport", city: "New York", country: "USA", timezone: "America/New_York", latitude: 40.6413, longitude: -73.7781),
        Airport(code: "LAX", name: "Los Angeles International Airport", city: "Los Angeles", country: "USA", timezone: "America/Los_Angeles", latitude: 33.9416, longitude: -118.4085),
        Airport(code: "ORD", name: "O'Hare International Airport", city: "Chicago", country: "USA", timezone: "America/Chicago", latitude: 41.9742, longitude: -87.9073),
        Airport(code: "SFO", name: "San Francisco International Airport", city: "San Francisco", country: "USA", timezone: "America/Los_Angeles", latitude: 37.6213, longitude: -122.3790),
        Airport(code: "MIA", name: "Miami International Airport", city: "Miami", country: "USA", timezone: "America/New_York", latitude: 25.7959, longitude: -80.2870),
        Airport(code: "DFW", name: "Dallas/Fort Worth International Airport", city: "Dallas", country: "USA", timezone: "America/Chicago", latitude: 32.8998, longitude: -97.0403),
        Airport(code: "LHR", name: "London Heathrow Airport", city: "London", country: "UK", timezone: "Europe/London", latitude: 51.4700, longitude: -0.4543),
        Airport(code: "CDG", name: "Charles de Gaulle Airport", city: "Paris", country: "France", timezone: "Europe/Paris", latitude: 49.0097, longitude: 2.5479),
        Airport(code: "NRT", name: "Narita International Airport", city: "Tokyo", country: "Japan", timezone: "Asia/Tokyo", latitude: 35.7720, longitude: 140.3929),
        Airport(code: "DXB", name: "Dubai International Airport", city: "Dubai", country: "UAE", timezone: "Asia/Dubai", latitude: 25.2532, longitude: 55.3657),
        Airport(code: "BOG", name: "El Dorado International Airport", city: "Bogotá", country: "Colombia", timezone: "America/Bogota", latitude: 4.7016, longitude: -74.1469),
        Airport(code: "SAL", name: "Monseñor Óscar Arnulfo Romero International Airport", city: "San Salvador", country: "El Salvador", timezone: "America/El_Salvador", latitude: 13.4409, longitude: -89.0556)
    ]

    static func createMockFlights(airports: [Airport]) -> [Flight] {
        var flights: [Flight] = []
        let calendar = Calendar.current

        // Upcoming flight 1: JFK to LAX
        if let jfk = airports.first(where: { $0.code == "JFK" }),
           let lax = airports.first(where: { $0.code == "LAX" }) {
            let departure = calendar.date(byAdding: .day, value: 3, to: Date())!
                .addingTimeInterval(3600 * 8) // 8 AM
            let arrival = departure.addingTimeInterval(3600 * 6) // 6 hour flight
            let boarding = departure.addingTimeInterval(-40 * 60) // 40 min before departure

            flights.append(Flight(
                flightNumber: "AA100",
                airline: "American Airlines",
                origin: jfk,
                destination: lax,
                scheduledDeparture: departure,
                scheduledArrival: arrival,
                status: .scheduled,
                departureGate: "B22",
                departureTerminal: "8",
                arrivalGate: "52A",
                arrivalTerminal: "4",
                baggageClaim: "3",
                aircraft: "Boeing 777-300ER",
                boardingTime: boarding,
                boardingPassImage: "boarding_pass_aa100"
            ))
        }

        // Upcoming flight 2: LAX to SFO
        if let lax = airports.first(where: { $0.code == "LAX" }),
           let sfo = airports.first(where: { $0.code == "SFO" }) {
            let departure = calendar.date(byAdding: .day, value: 5, to: Date())!
                .addingTimeInterval(3600 * 14) // 2 PM
            let arrival = departure.addingTimeInterval(3600 * 1.5) // 1.5 hour flight
            let boarding = departure.addingTimeInterval(-30 * 60) // 30 min before departure

            flights.append(Flight(
                flightNumber: "UA555",
                airline: "United Airlines",
                origin: lax,
                destination: sfo,
                scheduledDeparture: departure,
                scheduledArrival: arrival,
                status: .scheduled,
                departureGate: "C10",
                departureTerminal: "7",
                arrivalGate: "3",
                arrivalTerminal: "International",
                baggageClaim: "7",
                aircraft: "Airbus A320",
                boardingTime: boarding
            ))
        }

        // Upcoming flight 3: ORD to MIA (Delayed)
        if let ord = airports.first(where: { $0.code == "ORD" }),
           let mia = airports.first(where: { $0.code == "MIA" }) {
            let departure = calendar.date(byAdding: .day, value: 1, to: Date())!
                .addingTimeInterval(3600 * 10) // 10 AM
            let arrival = departure.addingTimeInterval(3600 * 3) // 3 hour flight

            flights.append(Flight(
                flightNumber: "DL200",
                airline: "Delta Air Lines",
                origin: ord,
                destination: mia,
                scheduledDeparture: departure,
                scheduledArrival: arrival,
                actualDeparture: departure.addingTimeInterval(3600 * 1.5), // 1.5 hour delay
                status: .delayed,
                departureGate: "A15",
                departureTerminal: "2",
                arrivalGate: "D8",
                arrivalTerminal: "North",
                baggageClaim: "4",
                aircraft: "Boeing 737-800",
                delay: 90
            ))
        }

        // In-air flight: SFO to NRT
        if let sfo = airports.first(where: { $0.code == "SFO" }),
           let nrt = airports.first(where: { $0.code == "NRT" }) {
            let departure = Date().addingTimeInterval(-3600 * 4) // Left 4 hours ago
            let arrival = departure.addingTimeInterval(3600 * 11) // 11 hour flight

            flights.append(Flight(
                flightNumber: "NH7",
                airline: "ANA",
                origin: sfo,
                destination: nrt,
                scheduledDeparture: departure,
                scheduledArrival: arrival,
                actualDeparture: departure,
                status: .inAir,
                departureGate: "G1",
                departureTerminal: "International",
                arrivalGate: "24",
                arrivalTerminal: "1",
                baggageClaim: "8",
                aircraft: "Boeing 787-9 Dreamliner"
            ))
        }

        // Past flight: LHR to JFK
        if let lhr = airports.first(where: { $0.code == "LHR" }),
           let jfk = airports.first(where: { $0.code == "JFK" }) {
            let departure = calendar.date(byAdding: .day, value: -2, to: Date())!
                .addingTimeInterval(3600 * 12) // 12 PM
            let arrival = departure.addingTimeInterval(3600 * 8) // 8 hour flight

            flights.append(Flight(
                flightNumber: "BA117",
                airline: "British Airways",
                origin: lhr,
                destination: jfk,
                scheduledDeparture: departure,
                scheduledArrival: arrival,
                actualDeparture: departure,
                actualArrival: arrival.addingTimeInterval(-600), // Arrived 10 min early
                status: .landed,
                departureGate: "A12",
                departureTerminal: "5",
                arrivalGate: "D7",
                arrivalTerminal: "7",
                baggageClaim: "5",
                aircraft: "Airbus A350-1000"
            ))
        }

        // Additional flights for search variety
        if let dfw = airports.first(where: { $0.code == "DFW" }),
           let cdg = airports.first(where: { $0.code == "CDG" }) {
            let departure = calendar.date(byAdding: .day, value: 7, to: Date())!
                .addingTimeInterval(3600 * 18) // 6 PM
            let arrival = departure.addingTimeInterval(3600 * 10) // 10 hour flight

            flights.append(Flight(
                flightNumber: "AF356",
                airline: "Air France",
                origin: dfw,
                destination: cdg,
                scheduledDeparture: departure,
                scheduledArrival: arrival,
                status: .scheduled,
                departureGate: "E20",
                departureTerminal: "D",
                arrivalGate: "2F",
                arrivalTerminal: "2E",
                baggageClaim: "6",
                aircraft: "Boeing 777-200ER"
            ))
        }

        if let mia = airports.first(where: { $0.code == "MIA" }),
           let dxb = airports.first(where: { $0.code == "DXB" }) {
            let departure = calendar.date(byAdding: .day, value: 10, to: Date())!
                .addingTimeInterval(3600 * 22) // 10 PM
            let arrival = departure.addingTimeInterval(3600 * 14) // 14 hour flight

            flights.append(Flight(
                flightNumber: "EK213",
                airline: "Emirates",
                origin: mia,
                destination: dxb,
                scheduledDeparture: departure,
                scheduledArrival: arrival,
                status: .scheduled,
                departureGate: "D12",
                departureTerminal: "South",
                arrivalGate: "B5",
                arrivalTerminal: "3",
                baggageClaim: "12",
                aircraft: "Airbus A380-800"
            ))
        }

        // AV 118: BOG to SAL (Avianca - Bogotá to San Salvador)
        if let bog = airports.first(where: { $0.code == "BOG" }),
           let sal = airports.first(where: { $0.code == "SAL" }) {
            let departure = calendar.date(byAdding: .day, value: 2, to: Date())!
                .addingTimeInterval(3600 * 9) // 9 AM
            let arrival = departure.addingTimeInterval(3600 * 2.5) // 2.5 hour flight
            let boarding = departure.addingTimeInterval(-35 * 60) // 35 min before departure

            flights.append(Flight(
                flightNumber: "AV118",
                airline: "Avianca",
                origin: bog,
                destination: sal,
                scheduledDeparture: departure,
                scheduledArrival: arrival,
                status: .scheduled,
                departureGate: "A8",
                departureTerminal: "1",
                arrivalGate: "12",
                arrivalTerminal: "Main",
                baggageClaim: "2",
                aircraft: "Airbus A320",
                boardingTime: boarding
            ))
        }

        return flights
    }
}
