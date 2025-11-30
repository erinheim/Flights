//
//  FlightService.swift
//  Flights
//
//  Created by Erin Heim on 11/25/25.
//

import Foundation
import SwiftUI

class FlightService: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var searchResults: [Flight] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var useRealData = false
    @Published var userFlights: [Flight] = [] // User-added flights

    private let aviationService = AviationStackService()
    private let userFlightsKey = "userFlights"

    init() {
        loadUserFlights()
        useRealData = aviationService.hasAPIKey()
        if !useRealData {
            loadMockData()
        }
    }

    // MARK: - User Flights Management

    func addUserFlight(_ flight: Flight) {
        userFlights.append(flight)
        saveUserFlights()
        // Refresh search results to include new flight
        searchFlights(query: "")
    }

    func deleteUserFlight(_ flight: Flight) {
        userFlights.removeAll { $0.id == flight.id }
        saveUserFlights()
    }

    private func saveUserFlights() {
        if let encoded = try? JSONEncoder().encode(userFlights) {
            UserDefaults.standard.set(encoded, forKey: userFlightsKey)
        }
    }

    private func loadUserFlights() {
        if let data = UserDefaults.standard.data(forKey: userFlightsKey),
           let decoded = try? JSONDecoder().decode([Flight].self, from: data) {
            userFlights = decoded
        }
    }

    // MARK: - Mock Data

    private func loadMockData() {
        let airports = MockData.airports
        let mockFlights = MockData.createMockFlights(airports: airports)

        // Create some sample trips
        let upcomingTrip = Trip(
            name: "New York Trip",
            flights: Array(mockFlights.filter { $0.isUpcoming }.prefix(2))
        )

        let businessTrip = Trip(
            name: "LA Business Trip",
            flights: Array(mockFlights.filter { $0.isUpcoming }.suffix(1))
        )

        trips = [upcomingTrip, businessTrip].filter { !$0.flights.isEmpty }
        searchResults = mockFlights
    }

    // MARK: - Trip Management

    func addTrip(name: String, flights: [Flight]) {
        let trip = Trip(name: name, flights: flights)
        trips.append(trip)
    }

    func deleteTrip(at offsets: IndexSet) {
        trips.remove(atOffsets: offsets)
    }

    func addFlightToTrip(flight: Flight, tripId: UUID) {
        if let index = trips.firstIndex(where: { $0.id == tripId }) {
            trips[index].flights.append(flight)
        }
    }

    // MARK: - Flight Search

    func searchFlights(query: String) {
        Task { [weak self] in
            await self?.performSearch(query: query)
        }
    }

    @MainActor
    private func performSearch(query: String) async {
        isLoading = true
        errorMessage = nil

        // Only hit the network when an API key is present
        if useRealData, aviationService.hasAPIKey(), !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                let apiFlights = try await aviationService.searchFlights(query: query)
                searchResults = mergeUserFlights(with: apiFlights, query: query)
                isLoading = false
                return
            } catch {
                // Surface API errors and fall back to local mock data
                errorMessage = (error as? AviationStackError)?.localizedDescription ?? error.localizedDescription
            }
        }

        searchResults = searchFlightsLocally(query: query)
        isLoading = false
    }

    private func searchFlightsLocally(query: String) -> [Flight] {
        let mockFlights = MockData.createMockFlights(airports: MockData.airports)
        let allFlights = userFlights + mockFlights

        guard !query.isEmpty else { return allFlights }

        return allFlights.filter { flight in
            flight.flightNumber.localizedCaseInsensitiveContains(query) ||
            flight.airline.localizedCaseInsensitiveContains(query) ||
            flight.origin.code.localizedCaseInsensitiveContains(query) ||
            flight.destination.code.localizedCaseInsensitiveContains(query) ||
            flight.origin.city.localizedCaseInsensitiveContains(query) ||
            flight.destination.city.localizedCaseInsensitiveContains(query)
        }
    }

    // Get a specific flight by flight number
    func getFlight(flightNumber: String, date: Date? = nil) async throws -> Flight? {
        if useRealData, aviationService.hasAPIKey() {
            do {
                return try await aviationService.getFlight(flightNumber: flightNumber, date: date)
            } catch {
                errorMessage = (error as? AviationStackError)?.localizedDescription ?? error.localizedDescription
            }
        }

        let allFlights = MockData.createMockFlights(airports: MockData.airports)
        return allFlights.first { $0.flightNumber == flightNumber }
    }

    // MARK: - Helper Methods

    var upcomingTrips: [Trip] {
        trips.filter { $0.isUpcoming || $0.isInProgress }
            .sorted { ($0.startDate ?? Date.distantPast) < ($1.startDate ?? Date.distantPast) }
    }

    var pastTrips: [Trip] {
        trips.filter { $0.isPast }
            .sorted { ($0.startDate ?? Date.distantPast) > ($1.startDate ?? Date.distantPast) }
    }

    private func mergeUserFlights(with apiFlights: [Flight], query: String) -> [Flight] {
        guard !userFlights.isEmpty else { return apiFlights }

        // Include user flights that match the same query to keep custom data visible alongside live results
        let matchingUserFlights = userFlights.filter { flight in
            query.isEmpty ||
            flight.flightNumber.localizedCaseInsensitiveContains(query) ||
            flight.airline.localizedCaseInsensitiveContains(query) ||
            flight.origin.code.localizedCaseInsensitiveContains(query) ||
            flight.destination.code.localizedCaseInsensitiveContains(query)
        }

        return matchingUserFlights + apiFlights
    }
}
