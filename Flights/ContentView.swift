//
//  ContentView.swift
//  Flights
//
//  Created by Monica Heim on 11/25/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var flightService: FlightService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MyTripsView()
                .tabItem {
                    Label("My Trips", systemImage: "airplane.departure")
                }
                .tag(0)

            FlightSearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FlightService())
}
