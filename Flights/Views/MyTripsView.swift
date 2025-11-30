//
//  MyTripsView.swift
//  Flights
//
//  Created by Erin Heim on 11/25/25.
//

import SwiftUI

struct MyTripsView: View {
    @EnvironmentObject var flightService: FlightService
    @State private var showingAddTrip = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if flightService.upcomingTrips.isEmpty && flightService.pastTrips.isEmpty {
                        emptyState
                    } else {
                        // Upcoming Trips
                        if !flightService.upcomingTrips.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Upcoming")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)

                                ForEach(flightService.upcomingTrips) { trip in
                                    TripCard(trip: trip)
                                        .padding(.horizontal)
                                }
                            }
                        }

                        // Past Trips
                        if !flightService.pastTrips.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Past Trips")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)

                                ForEach(flightService.pastTrips) { trip in
                                    TripCard(trip: trip)
                                        .padding(.horizontal)
                                        .opacity(0.7)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("My Trips")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTrip = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTrip) {
                AddTripView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            Text("No Trips Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Search for flights and add them to your trips")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MyTripsView()
        .environmentObject(FlightService())
}
