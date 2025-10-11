//
//  ExploreMapView.swift
//  Foodi
//
//  Created by Tyler Hedberg on 10/11/25.
//

import SwiftUI
import MapKit

struct ExploreMapView: View {
    // iOS 17 Map API
    @State private var camera = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.2694, longitude: -118.7815),
            span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
        )
    )

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $camera)
                .ignoresSafeArea()

            NavigationLink(value: Route.search) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text("Search restaurants, cuisines…")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(12)
                .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.black.opacity(0.08))
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
}
