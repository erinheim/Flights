//
//  AddFlightView.swift
//  Flights
//
//  Created by Erin Heim on 11/25/25.
//

import SwiftUI

struct AddFlightView: View {
    @EnvironmentObject var flightService: FlightService
    @Environment(\.dismiss) var dismiss

    @State private var flightNumber = ""
    @State private var airline = ""
    @State private var originCode = ""
    @State private var originCity = ""
    @State private var destinationCode = ""
    @State private var destinationCity = ""
    @State private var departureDate = Date()
    @State private var arrivalDate = Date().addingTimeInterval(3600 * 2)
    @State private var departureGate = ""
    @State private var departureTerminal = ""
    @State private var arrivalGate = ""
    @State private var arrivalTerminal = ""
    @State private var baggageClaim = ""
    @State private var aircraft = ""
    @State private var selectedStatus: FlightStatus = .scheduled

    var body: some View {
        NavigationStack {
            Form {
                Section("Flight Information") {
                    TextField("Flight Number (e.g., AV118)", text: $flightNumber)
                        .textInputAutocapitalization(.characters)
                    TextField("Airline (e.g., Avianca)", text: $airline)

                    Picker("Status", selection: $selectedStatus) {
                        Text("Scheduled").tag(FlightStatus.scheduled)
                        Text("Boarding").tag(FlightStatus.boarding)
                        Text("Departed").tag(FlightStatus.departed)
                        Text("In Air").tag(FlightStatus.inAir)
                        Text("Landed").tag(FlightStatus.landed)
                        Text("Delayed").tag(FlightStatus.delayed)
                        Text("Cancelled").tag(FlightStatus.cancelled)
                    }
                }

                Section("Origin Airport") {
                    TextField("Airport Code (e.g., BOG)", text: $originCode)
                        .textInputAutocapitalization(.characters)
                    TextField("City (e.g., Bogotá)", text: $originCity)
                    TextField("Terminal (optional)", text: $departureTerminal)
                    TextField("Gate (optional)", text: $departureGate)
                }

                Section("Destination Airport") {
                    TextField("Airport Code (e.g., SAL)", text: $destinationCode)
                        .textInputAutocapitalization(.characters)
                    TextField("City (e.g., San Salvador)", text: $destinationCity)
                    TextField("Terminal (optional)", text: $arrivalTerminal)
                    TextField("Gate (optional)", text: $arrivalGate)
                    TextField("Baggage Claim (optional)", text: $baggageClaim)
                }

                Section("Flight Times") {
                    DatePicker("Departure", selection: $departureDate)
                    DatePicker("Arrival", selection: $arrivalDate)
                }

                Section("Additional Details (Optional)") {
                    TextField("Aircraft Type (e.g., A320)", text: $aircraft)
                }
            }
            .navigationTitle("Add Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveFlight()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !flightNumber.isEmpty &&
        !airline.isEmpty &&
        !originCode.isEmpty &&
        !originCity.isEmpty &&
        !destinationCode.isEmpty &&
        !destinationCity.isEmpty
    }

    private func saveFlight() {
        // Create origin airport
        let origin = Airport(
            code: originCode.uppercased(),
            name: "\(originCity) Airport",
            city: originCity,
            country: "Unknown",
            timezone: "UTC",
            latitude: 0.0,
            longitude: 0.0
        )

        // Create destination airport
        let destination = Airport(
            code: destinationCode.uppercased(),
            name: "\(destinationCity) Airport",
            city: destinationCity,
            country: "Unknown",
            timezone: "UTC",
            latitude: 0.0,
            longitude: 0.0
        )

        // Calculate boarding time (40 min before departure)
        let boardingTime = departureDate.addingTimeInterval(-40 * 60)

        // Create flight
        let flight = Flight(
            flightNumber: flightNumber.uppercased(),
            airline: airline,
            origin: origin,
            destination: destination,
            scheduledDeparture: departureDate,
            scheduledArrival: arrivalDate,
            status: selectedStatus,
            departureGate: departureGate.isEmpty ? nil : departureGate,
            departureTerminal: departureTerminal.isEmpty ? nil : departureTerminal,
            arrivalGate: arrivalGate.isEmpty ? nil : arrivalGate,
            arrivalTerminal: arrivalTerminal.isEmpty ? nil : arrivalTerminal,
            baggageClaim: baggageClaim.isEmpty ? nil : baggageClaim,
            aircraft: aircraft.isEmpty ? nil : aircraft,
            boardingTime: boardingTime
        )

        flightService.addUserFlight(flight)
        dismiss()
    }
}

#Preview {
    AddFlightView()
        .environmentObject(FlightService())
}
