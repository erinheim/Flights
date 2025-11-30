//
//  TripCard.swift
//  Flights
//
//  Created by Erin Heim on 11/25/25.
//

import SwiftUI

struct TripCard: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Trip name and dates
            HStack {
                VStack(alignment: .leading) {
                    Text(trip.name)
                        .font(.headline)
                    if let start = trip.startDate, let end = trip.endDate {
                        Text("\(formatDate(start)) - \(formatDate(end))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if trip.isInProgress {
                    Text("In Progress")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(6)
                }
            }

            Divider()

            // Flights in the trip
            ForEach(Array(trip.flights.enumerated()), id: \.element.id) { index, flight in
                NavigationLink(destination: FlightDetailView(flight: flight)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(flight.origin.code) → \(flight.destination.code)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("\(flight.airline) \(flight.flightNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(formatTime(flight.departureTime))
                                .font(.subheadline)
                            Label(flight.status.rawValue, systemImage: flight.status.icon)
                                .font(.caption)
                                .foregroundColor(flight.status.color)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())

                // Show layover information between flights
                if index < trip.flights.count - 1 {
                    let layover = trip.layovers[index]
                    let arrivalAirport = layover.fromFlight.destination.code
                    let departureAirport = layover.toFlight.origin.code

                    HStack {
                        Spacer()
                        Group {
                            Text("Layover: ")
                                .foregroundColor(.secondary)
                            +
                            Text("\(formatLayoverDuration(layover.duration))")
                                .foregroundColor(.indigo)
                                .fontWeight(.semibold)
                            +
                            Text(arrivalAirport == departureAirport
                                 ? " at \(arrivalAirport)"
                                 : " (\(arrivalAirport) → \(departureAirport))")
                                .foregroundColor(.primary)
                        }
                        .font(.caption)
                        .padding(.vertical, 8)
                        Spacer()
                    }

                    Divider()
                        .padding(.leading, 20)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatLayoverDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    let airports = MockData.airports
    let flights = MockData.createMockFlights(airports: airports)
    let trip = Trip(name: "Summer Vacation", flights: Array(flights.prefix(2)))

    return TripCard(trip: trip)
        .padding()
}
