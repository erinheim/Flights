//
//  FlightStatus.swift
//  Flights
//
//  Created by Erin Heim on 11/25/25.
//

import Foundation
import SwiftUI

enum FlightStatus: String, Codable {
    case scheduled = "Scheduled"
    case boarding = "Boarding"
    case departed = "Departed"
    case inAir = "In Air"
    case landed = "Landed"
    case delayed = "Delayed"
    case cancelled = "Cancelled"

    var color: Color {
        switch self {
        case .scheduled:
            return .blue
        case .boarding:
            return .orange
        case .departed, .inAir:
            return .green
        case .landed:
            return .gray
        case .delayed:
            return .orange
        case .cancelled:
            return .red
        }
    }

    var icon: String {
        switch self {
        case .scheduled:
            return "clock"
        case .boarding:
            return "figure.walk"
        case .departed, .inAir:
            return "airplane"
        case .landed:
            return "checkmark.circle"
        case .delayed:
            return "exclamationmark.triangle"
        case .cancelled:
            return "xmark.circle"
        }
    }
}
