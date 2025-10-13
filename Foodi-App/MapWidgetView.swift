//
//  MapWidgetView.swift
//  Foodi
//
//  Created by Francisco Campa on 10/12/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapWidgetView: View {
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.2411, longitude: -119.0434),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    @State private var searchText = ""
    @State private var searchResults: [RestaurantResult] = []
    @State private var selectedRestaurantID: UUID? = nil
    @State private var userLocation: CLLocation? = nil
    @State private var zoomLevel: Double = 0.05
    
    private let restaurantManager = RestaurantSearchManager()
    private let locationManager = CLLocationManager()
    
    var body: some View {
        ZStack(alignment: .top) {
            // MARK: - Main Map
            Map(position: $position, selection: $selectedRestaurantID) {
                ForEach(searchResults) { result in
                    Marker(result.item.name ?? "Unknown", coordinate: result.item.location.coordinate)
                        .tag(result.id)
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            .onAppear { requestUserLocation() }
            
            // MARK: - Overlay UI
            VStack {
                // Search bar
                searchBar
                    .padding(.top, 10)
                    .padding(.horizontal)
                
                Spacer()
                
                // Zoom controls
                zoomControls
                    .padding(.bottom, 40)
            }
            
            // MARK: - Info Card
            if let selected = searchResults.first(where: { $0.id == selectedRestaurantID }) {
                restaurantInfoCard(for: selected)
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: selectedRestaurantID)
            }
        }
    }
    
    // MARK: - UI Components
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search restaurants...", text: $searchText, onCommit: performSearch)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults.removeAll()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Zoom Controls
    private var zoomControls: some View {
        VStack(spacing: 10) {
            Button {
                changeZoom(factor: 0.7)   // zoom in
            } label: {
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 22))
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Button {
                changeZoom(factor: 1.3)   // zoom out
            } label: {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 22))
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Zoom Handler
    private func changeZoom(factor: Double) {
        guard let currentRegion = position.region else { return }

        let newSpan = MKCoordinateSpan(
            latitudeDelta: currentRegion.span.latitudeDelta * factor,
            longitudeDelta: currentRegion.span.longitudeDelta * factor
        )

        let newRegion = MKCoordinateRegion(center: currentRegion.center, span: newSpan)

        withAnimation(.easeInOut(duration: 0.25)) {
            position = .region(newRegion)
        }
    }

    
    private func restaurantInfoCard(for restaurant: RestaurantResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(restaurant.item.name ?? "Unknown")
                .font(.headline)
            
            if let userLoc = userLocation {
                let distance = restaurant.item.location.distance(from: userLoc)
                Text(String(format: "📍 %.1f km away", distance / 1000))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text(String(format: "⭐ Relevance: %.0f%%", restaurant.relevance * 100))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // User rating placeholder - just so we can show we have something, we can add real variation later
            HStack(spacing: 4) {
                ForEach(0..<5) { _ in
                    Image(systemName: "fork.knife.circle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 18))
                }
            }
            .padding(.top, 4)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    // MARK: - Logic
    
    private func performSearch() {
        guard let region = position.region else { return }
        restaurantManager.searchRestaurants(query: searchText, region: region) { results in
            DispatchQueue.main.async {
                searchResults = results
            }
        }
    }
    
    private func requestUserLocation() {
        locationManager.requestWhenInUseAuthorization()
        if let loc = locationManager.location {
            userLocation = loc
        } else {
            // fallback location (CSU Channel Islands)
            userLocation = CLLocation(latitude: 34.2411, longitude: -119.0434)
        }
    }
    
    private func updateMapZoom() {
        if let region = position.region {
            position = .region(
                MKCoordinateRegion(
                    center: region.center,
                    span: MKCoordinateSpan(latitudeDelta: zoomLevel, longitudeDelta: zoomLevel)
                )
            )
        }
    }
}
