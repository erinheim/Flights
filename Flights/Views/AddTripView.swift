//
//  AddTripView.swift
//  Flights
//
//  Created by Monica Heim on 11/25/25.
//

import SwiftUI

struct AddTripView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var flightService: FlightService
    @State private var tripName = ""
    @State private var selectedFlights: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    TextField("Trip Name", text: $tripName)
                }

                Section("Select Flights") {
                    if flightService.searchResults.isEmpty {
                        Text("No flights available")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(flightService.searchResults.filter { $0.isUpcoming }) { flight in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(flight.origin.code) → \(flight.destination.code)")
                                        .font(.headline)
                                    Text("\(flight.airline) \(flight.flightNumber)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatDate(flight.scheduledDeparture))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if selectedFlights.contains(flight.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedFlights.contains(flight.id) {
                                    selectedFlights.remove(flight.id)
                                } else {
                                    selectedFlights.insert(flight.id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTrip()
                    }
                    .disabled(tripName.isEmpty || selectedFlights.isEmpty)
                }
            }
        }
    }

    private func addTrip() {
        let flights = flightService.searchResults.filter { selectedFlights.contains($0.id) }
            .sorted { $0.scheduledDeparture < $1.scheduledDeparture }

        flightService.addTrip(name: tripName, flights: flights)
        dismiss()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    AddTripView()
        .environmentObject(FlightService())
}
