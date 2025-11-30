//
//  Trip.swift
//  Flights
//
//  Created by Erin Heim on 11/25/25.
//

import Foundation

struct Trip: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var flights: [Flight]

    init(id: UUID = UUID(), name: String, flights: [Flight]) {
        self.id = id
        self.name = name
        self.flights = flights
    }

    var startDate: Date? {
        flights.first?.scheduledDeparture
    }

    var endDate: Date? {
        flights.last?.scheduledArrival
    }

    var isUpcoming: Bool {
        guard let start = startDate else { return false }
        return start > Date()
    }

    var isInProgress: Bool {
        guard let start = startDate, let end = endDate else { return false }
        let now = Date()
        return now >= start && now <= end
    }

    var isPast: Bool {
        guard let end = endDate else { return false }
        return end < Date()
    }

    // Calculate layover times between consecutive flights
    var layovers: [(fromFlight: Flight, toFlight: Flight, duration: TimeInterval)] {
        guard flights.count > 1 else { return [] }

        var layoverInfo: [(fromFlight: Flight, toFlight: Flight, duration: TimeInterval)] = []

        for i in 0..<(flights.count - 1) {
            let currentFlight = flights[i]
            let nextFlight = flights[i + 1]

            // Calculate layover time between arrival and next departure
            let layoverDuration = nextFlight.scheduledDeparture.timeIntervalSince(currentFlight.scheduledArrival)

            layoverInfo.append((fromFlight: currentFlight, toFlight: nextFlight, duration: layoverDuration))
        }

        return layoverInfo
    }
}
