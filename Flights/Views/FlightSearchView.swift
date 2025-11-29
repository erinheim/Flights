//
//  FlightSearchView.swift
//  Flights
//
//  Created by Monica Heim on 11/25/25.
//

import SwiftUI

struct FlightSearchView: View {
    @EnvironmentObject var flightService: FlightService
    @State private var searchText = ""
    @State private var showingAddFlight = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        // Demo Data Banner
                        HStack {
                            Image(systemName: "airplane.circle.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Your Flights")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Add your own flights or browse examples")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)

                        // Error Message
                        if let error = flightService.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("API Error")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(error)
                                        .font(.caption)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }

                        if flightService.searchResults.isEmpty && !flightService.isLoading {
                            emptyState
                        } else {
                            ForEach(flightService.searchResults) { flight in
                                NavigationLink(destination: FlightDetailView(flight: flight)) {
                                    FlightCard(flight: flight)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical)
                }

                // Loading Overlay
                if flightService.isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Searching flights...")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        .padding(32)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 20)
                    }
                }
            }
            .navigationTitle("Search Flights")
            .searchable(text: $searchText, prompt: "Flight number, airline, or city")
            .onChange(of: searchText) { oldValue, newValue in
                flightService.searchFlights(query: newValue)
            }
            .onAppear {
                flightService.searchFlights(query: searchText)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddFlight = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddFlight) {
                AddFlightView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            Text("No Flights Found")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Try searching with a different flight number, airline, or city")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FlightSearchView()
        .environmentObject(FlightService())
}
