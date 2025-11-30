//
//  FlightsApp.swift
//  Flights
//
//  Created by Erin Heim on 11/25/25.
//

import SwiftUI

@main
struct FlightsApp: App {
    @StateObject private var flightService = FlightService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(flightService)
        }
    }
}
