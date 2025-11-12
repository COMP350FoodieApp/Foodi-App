//
//  MapWidgetView.swift
//  Foodi
//
//  Created by Hasan on 10/12/25.
//

import Foundation
import MapKit

struct RestaurantResult: Identifiable, Hashable, Equatable {
    let id = UUID()
    let item: MKMapItem
    let distance: Double
    let relevance: Double

    static func == (lhs: RestaurantResult, rhs: RestaurantResult) -> Bool {
        lhs.id == rhs.id
    }
}

class RestaurantSearchManager {
    func searchRestaurants(
        query: String?,
        region: MKCoordinateRegion,
        completion: @escaping ([RestaurantResult]) -> Void
    ) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query?.isEmpty == false ? query : "restaurant"
        request.region = region

        MKLocalSearch(request: request).start { response, error in
            guard let response = response, error == nil else {
                completion([])
                return
            }

            let filtered = response.mapItems.filter {
                if let cat = $0.pointOfInterestCategory {
                    return cat == .restaurant || cat == .foodMarket
                }
                return $0.name?.localizedCaseInsensitiveContains("restaurant") ?? false
            }

            let results = filtered.compactMap { item -> RestaurantResult? in
                let distance = item.location.distance(
                    from: CLLocation(latitude: region.center.latitude,
                                     longitude: region.center.longitude)
                )
                let match = item.name?.lowercased()
                    .contains(query?.lowercased() ?? "") ?? false
                let relevance = match ? 0.9 : 0.6
                return RestaurantResult(item: item,
                                        distance: distance,
                                        relevance: relevance)
            }

            completion(results.sorted {
                $0.relevance == $1.relevance
                    ? $0.distance < $1.distance
                    : $0.relevance > $1.relevance
            })
        }
    }
}
