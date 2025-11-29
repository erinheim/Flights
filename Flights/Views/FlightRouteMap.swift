//
//  FlightRouteMap.swift
//  Flights
//
//  Created by Monica Heim on 11/25/25.
//

import SwiftUI
import MapKit

struct FlightRouteMap: View {
    let flights: [Flight]
    @State private var cameraPosition: MapCameraPosition

    // Single flight initializer
    init(flight: Flight) {
        self.flights = [flight]
        _cameraPosition = State(initialValue: Self.calculateCameraPosition(for: [flight]))
    }

    // Multiple flights initializer (for trips)
    init(flights: [Flight]) {
        self.flights = flights
        _cameraPosition = State(initialValue: Self.calculateCameraPosition(for: flights))
    }

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(Array(flights.enumerated()), id: \.element.id) { index, flight in
                // Origin marker
                Annotation(flight.origin.code, coordinate: flight.origin.coordinate) {
                    VStack(spacing: 4) {
                        Image(systemName: index == 0 ? "airplane.departure" : "airplane")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(index == 0 ? Color.green : Color.orange))
                        Text(flight.origin.code)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(index == 0 ? Color.green : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }

                // Destination marker
                Annotation(flight.destination.code, coordinate: flight.destination.coordinate) {
                    VStack(spacing: 4) {
                        Image(systemName: index == flights.count - 1 ? "airplane.arrival" : "airplane")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(index == flights.count - 1 ? Color.blue : Color.orange))
                        Text(flight.destination.code)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(index == flights.count - 1 ? Color.blue : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }

                // Flight path line - solid line
                MapPolyline(coordinates: [flight.origin.coordinate, flight.destination.coordinate])
                    .stroke(Color.blue, lineWidth: 3)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }

    // Calculate appropriate camera position for all flights
    private static func calculateCameraPosition(for flights: [Flight]) -> MapCameraPosition {
        guard !flights.isEmpty else {
            return .automatic
        }

        // Collect all unique coordinates
        var allCoordinates: [CLLocationCoordinate2D] = []
        for flight in flights {
            allCoordinates.append(flight.origin.coordinate)
            allCoordinates.append(flight.destination.coordinate)
        }

        // For multiple flights spanning large distances, use a globe view
        if flights.count > 1 {
            // Calculate the bounds of all coordinates
            let latitudes = allCoordinates.map { $0.latitude }
            let longitudes = allCoordinates.map { $0.longitude }

            guard let minLat = latitudes.min(),
                  let maxLat = latitudes.max(),
                  let minLon = longitudes.min(),
                  let maxLon = longitudes.max() else {
                return .automatic
            }

            let latDelta = maxLat - minLat
            let lonDelta = maxLon - minLon

            // If the flights span a large area (e.g., intercontinental), show more of the globe
            let shouldShowGlobe = latDelta > 30 || lonDelta > 40

            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )

            let span = MKCoordinateSpan(
                latitudeDelta: max(latDelta * (shouldShowGlobe ? 2.0 : 1.8), shouldShowGlobe ? 60 : 5),
                longitudeDelta: max(lonDelta * (shouldShowGlobe ? 2.0 : 1.8), shouldShowGlobe ? 80 : 5)
            )

            let region = MKCoordinateRegion(center: center, span: span)
            return .region(region)
        } else {
            // Single flight - show just that route
            let flight = flights[0]
            let center = CLLocationCoordinate2D(
                latitude: (flight.origin.coordinate.latitude + flight.destination.coordinate.latitude) / 2,
                longitude: (flight.origin.coordinate.longitude + flight.destination.coordinate.longitude) / 2
            )

            let latDelta = abs(flight.origin.coordinate.latitude - flight.destination.coordinate.latitude) * 1.5
            let lonDelta = abs(flight.origin.coordinate.longitude - flight.destination.coordinate.longitude) * 1.5

            let span = MKCoordinateSpan(
                latitudeDelta: max(latDelta, 5),
                longitudeDelta: max(lonDelta, 5)
            )

            let region = MKCoordinateRegion(center: center, span: span)
            return .region(region)
        }
    }
}

#Preview {
    FlightRouteMap(flight: MockData.createMockFlights(airports: MockData.airports)[0])
        .frame(height: 300)
}
