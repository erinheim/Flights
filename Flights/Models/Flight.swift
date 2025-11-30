//
//  Flight.swift
//  Flights
//
//  Created by Erin Heim on 11/25/25.
//

import Foundation
import SwiftUI

struct Flight: Identifiable, Codable, Hashable {
    let id: UUID
    let flightNumber: String
    let airline: String
    let origin: Airport
    let destination: Airport
    let scheduledDeparture: Date
    let scheduledArrival: Date
    var actualDeparture: Date?
    var actualArrival: Date?
    var status: FlightStatus
    var departureGate: String?
    var departureTerminal: String?
    var arrivalGate: String?
    var arrivalTerminal: String?
    var baggageClaim: String?
    var aircraft: String?
    var delay: Int? // in minutes
    var boardingTime: Date? // When boarding starts
    var boardingPassImage: String? // Image asset name or URL

    init(id: UUID = UUID(),
         flightNumber: String,
         airline: String,
         origin: Airport,
         destination: Airport,
         scheduledDeparture: Date,
         scheduledArrival: Date,
         actualDeparture: Date? = nil,
         actualArrival: Date? = nil,
         status: FlightStatus,
         departureGate: String? = nil,
         departureTerminal: String? = nil,
         arrivalGate: String? = nil,
         arrivalTerminal: String? = nil,
         baggageClaim: String? = nil,
         aircraft: String? = nil,
         delay: Int? = nil,
         boardingTime: Date? = nil,
         boardingPassImage: String? = nil) {
        self.id = id
        self.flightNumber = flightNumber
        self.airline = airline
        self.origin = origin
        self.destination = destination
        self.scheduledDeparture = scheduledDeparture
        self.scheduledArrival = scheduledArrival
        self.actualDeparture = actualDeparture
        self.actualArrival = actualArrival
        self.status = status
        self.departureGate = departureGate
        self.departureTerminal = departureTerminal
        self.arrivalGate = arrivalGate
        self.arrivalTerminal = arrivalTerminal
        self.baggageClaim = baggageClaim
        self.aircraft = aircraft
        self.delay = delay
        self.boardingTime = boardingTime
        self.boardingPassImage = boardingPassImage
    }

    var departureTime: Date {
        actualDeparture ?? scheduledDeparture
    }

    var arrivalTime: Date {
        actualArrival ?? scheduledArrival
    }

    var duration: TimeInterval {
        arrivalTime.timeIntervalSince(departureTime)
    }

    var isUpcoming: Bool {
        scheduledDeparture > Date()
    }

    var isPast: Bool {
        scheduledArrival < Date()
    }

    // Calculate boarding time if not provided (typically 30-45 min before departure)
    var estimatedBoardingTime: Date {
        if let boardingTime = boardingTime {
            return boardingTime
        }
        // Default: 40 minutes before scheduled departure
        return scheduledDeparture.addingTimeInterval(-40 * 60)
    }

    // Determine if flight is delayed, early, or on time
    var timeStatus: TimeStatus {
        if let delay = delay {
            if delay > 15 {
                return .delayed(minutes: delay)
            } else if delay < -5 {
                return .early(minutes: abs(delay))
            }
        }

        // Check actual vs scheduled times
        if let actualDep = actualDeparture {
            let diff = Int(actualDep.timeIntervalSince(scheduledDeparture) / 60)
            if diff > 15 {
                return .delayed(minutes: diff)
            } else if diff < -5 {
                return .early(minutes: abs(diff))
            }
        }

        if let actualArr = actualArrival {
            let diff = Int(actualArr.timeIntervalSince(scheduledArrival) / 60)
            if diff > 15 {
                return .delayed(minutes: diff)
            } else if diff < -5 {
                return .early(minutes: abs(diff))
            }
        }

        return .onTime
    }
}

// MARK: - Time Status

enum TimeStatus {
    case onTime
    case early(minutes: Int)
    case delayed(minutes: Int)

    var displayText: String {
        switch self {
        case .onTime:
            return "On Time"
        case .early(let minutes):
            return "Early by \(minutes) min"
        case .delayed(let minutes):
            return "Delayed \(minutes) min"
        }
    }

    var color: Color {
        switch self {
        case .onTime:
            return .green
        case .early:
            return .blue
        case .delayed:
            return .orange
        }
    }

    var icon: String {
        switch self {
        case .onTime:
            return "checkmark.circle.fill"
        case .early:
            return "arrow.down.circle.fill"
        case .delayed:
            return "clock.fill"
        }
    }
}
