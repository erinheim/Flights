//
//  FlightDetailView.swift
//  Flights
//
//  Created by Monica Heim on 11/25/25.
//

import SwiftUI

struct FlightDetailView: View {
    let flight: Flight
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Card with Route
                routeSection

                // Route Map
                FlightRouteMap(flight: flight)
                    .frame(height: 250)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                // Boarding Pass Section
                if let boardingPass = flight.boardingPassImage {
                    boardingPassSection(imageName: boardingPass)
                }

                // Status Card
                statusSection

                // Flight Information
                flightInfoSection

                // Airport Information
                airportInfoSection

                // Aircraft Information
                if flight.aircraft != nil {
                    aircraftSection
                }
            }
            .padding()
        }
        .navigationTitle(flight.flightNumber)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var routeSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(flight.origin.code)
                        .font(.system(size: 36, weight: .bold))
                    Text(flight.origin.city)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(flight.origin.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack {
                    Image(systemName: "airplane")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text(formatDuration(flight.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text(flight.destination.code)
                        .font(.system(size: 36, weight: .bold))
                    Text(flight.destination.city)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(flight.destination.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("Departure")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(flight.departureTime))
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(formatFullDate(flight.scheduledDeparture))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Arrival")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(flight.arrivalTime))
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(formatFullDate(flight.scheduledArrival))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(flight.status.rawValue, systemImage: flight.status.icon)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(flight.status.color)
                    .cornerRadius(8)

                Spacer()

                // Time Status Badge
                Label(flight.timeStatus.displayText, systemImage: flight.timeStatus.icon)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(flight.timeStatus.color)
                    .cornerRadius(8)
            }

            // Boarding Time
            if flight.isUpcoming {
                Divider()
                HStack {
                    Image(systemName: "figure.walk.departure")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Boarding Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatTime(flight.estimatedBoardingTime))
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    Spacer()

                    // Time until boarding
                    let timeUntilBoarding = flight.estimatedBoardingTime.timeIntervalSince(Date())
                    if timeUntilBoarding > 0 {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Boards in")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatTimeInterval(timeUntilBoarding))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }

            if let actualDep = flight.actualDeparture {
                Divider()
                HStack {
                    Text("Actual Departure:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatTime(actualDep))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }

            if let actualArr = flight.actualArrival {
                HStack {
                    Text("Actual Arrival:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatTime(actualArr))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var flightInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Flight Information")
                .font(.headline)

            InfoRow(label: "Airline", value: flight.airline)
            InfoRow(label: "Flight Number", value: flight.flightNumber)

            Divider()

            // Departure Information
            VStack(alignment: .leading, spacing: 8) {
                Text("Departure - \(flight.origin.code)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)

                if let terminal = flight.departureTerminal {
                    InfoRow(label: "Terminal", value: terminal)
                }

                if let gate = flight.departureGate {
                    InfoRow(label: "Gate", value: gate)
                }
            }

            Divider()

            // Arrival Information
            VStack(alignment: .leading, spacing: 8) {
                Text("Arrival - \(flight.destination.code)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)

                if let terminal = flight.arrivalTerminal {
                    InfoRow(label: "Terminal", value: terminal)
                }

                if let gate = flight.arrivalGate {
                    InfoRow(label: "Gate", value: gate)
                }

                if let baggage = flight.baggageClaim {
                    InfoRow(label: "Baggage Claim", value: baggage)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var airportInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Airports")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Departure")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                InfoRow(label: "Airport", value: flight.origin.name)
                InfoRow(label: "City", value: "\(flight.origin.city), \(flight.origin.country)")
                InfoRow(label: "Code", value: flight.origin.code)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Arrival")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                InfoRow(label: "Airport", value: flight.destination.name)
                InfoRow(label: "City", value: "\(flight.destination.city), \(flight.destination.country)")
                InfoRow(label: "Code", value: flight.destination.code)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var aircraftSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aircraft")
                .font(.headline)

            if let aircraft = flight.aircraft {
                InfoRow(label: "Type", value: aircraft)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private func boardingPassSection(imageName: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Boarding Pass")
                    .font(.headline)
                Spacer()
                Image(systemName: "qrcode")
                    .font(.title3)
                    .foregroundColor(.blue)
            }

            // Placeholder for boarding pass image
            // In a real app, this would display the actual boarding pass
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 200)

                VStack(spacing: 12) {
                    Image(systemName: "ticket.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)

                    Text("Boarding Pass")
                        .font(.headline)

                    Text("\(flight.airline) \(flight.flightNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 20) {
                        VStack {
                            Text(flight.origin.code)
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Image(systemName: "arrow.right")
                            .foregroundColor(.blue)

                        VStack {
                            Text(flight.destination.code)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }

                    if let gate = flight.departureGate {
                        Text("Gate: \(gate)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }

            Text("Tap to view full boarding pass")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
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

    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        FlightDetailView(flight: MockData.createMockFlights(airports: MockData.airports)[0])
    }
}
