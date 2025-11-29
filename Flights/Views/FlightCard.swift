//
//  FlightCard.swift
//  Flights
//
//  Created by Monica Heim on 11/25/25.
//

import SwiftUI

struct FlightCard: View {
    let flight: Flight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Airline and flight number
            HStack {
                Text(flight.airline)
                    .font(.headline)
                Spacer()
                Text(flight.flightNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Route
            HStack(alignment: .center, spacing: 8) {
                // Origin
                VStack(alignment: .leading) {
                    Text(flight.origin.code)
                        .font(.system(size: 28, weight: .bold))
                    Text(flight.origin.city)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(flight.departureTime))
                        .font(.subheadline)
                }

                Spacer()

                // Arrow and duration
                VStack {
                    Image(systemName: "airplane")
                        .font(.title3)
                        .foregroundColor(.blue)
                    Text(formatDuration(flight.duration))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Destination
                VStack(alignment: .trailing) {
                    Text(flight.destination.code)
                        .font(.system(size: 28, weight: .bold))
                    Text(flight.destination.city)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(flight.arrivalTime))
                        .font(.subheadline)
                }
            }

            // Status and details
            HStack {
                Label(flight.status.rawValue, systemImage: flight.status.icon)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(flight.status.color)
                    .cornerRadius(8)

                // Time status (On Time, Delayed, Early)
                Label(flight.timeStatus.displayText, systemImage: flight.timeStatus.icon)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(flight.timeStatus.color)
                    .cornerRadius(6)

                Spacer()

                if let gate = flight.departureGate {
                    VStack(alignment: .trailing) {
                        Text("Gate")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(gate)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

#Preview {
    FlightCard(flight: MockData.createMockFlights(airports: MockData.airports)[0])
        .padding()
}
