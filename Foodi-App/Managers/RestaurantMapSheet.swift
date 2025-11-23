import SwiftUI
import MapKit
import CoreLocation

struct RestaurantMapSheet: View {
    let target: CLLocationCoordinate2D
    let restaurantName: String


    @Environment(\.dismiss) var dismiss

    @State private var position: MapCameraPosition = .automatic
    @State private var zoomLevel: Double = 0.02    // default zoom in

    var body: some View {
        ZStack(alignment: .topTrailing) {

            // MARK: - MAP
            Map(position: $position) {
                Marker(restaurantName, coordinate: target)

            }
            .mapStyle(.standard)
            .onAppear {
                centerOnRestaurant()
            }
            .onMapCameraChange { context in
                // Keep position state in sync with user's moves
                position = .region(context.region)
            }
            .ignoresSafeArea()

            // MARK: - CLOSE BUTTON
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
                    .padding(.top, 20)
                    .padding(.trailing, 20)
            }

            // MARK: - ZOOM CONTROLS
            VStack(spacing: 10) {
                Button {
                    changeZoom(factor: 0.7) // Zoom in
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.system(size: 22))
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }

                Button {
                    changeZoom(factor: 1.3) // Zoom out
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.system(size: 22))
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(.trailing, 20)
            .padding(.top, 80)
        }
    }

    // MARK: - Center on Target
    private func centerOnRestaurant() {
        let region = MKCoordinateRegion(
            center: target,
            span: MKCoordinateSpan(latitudeDelta: zoomLevel,
                                   longitudeDelta: zoomLevel)
        )

        withAnimation(.easeInOut) {
            position = .region(region)
        }
    }

    // MARK: - Zoom Handler
    private func changeZoom(factor: Double) {
        guard let region = position.region else { return }

        let newSpan = MKCoordinateSpan(
            latitudeDelta: region.span.latitudeDelta * factor,
            longitudeDelta: region.span.longitudeDelta * factor
        )

        let newRegion = MKCoordinateRegion(center: region.center, span: newSpan)

        withAnimation(.easeInOut(duration: 0.25)) {
            position = .region(newRegion)
        }
    }
}
