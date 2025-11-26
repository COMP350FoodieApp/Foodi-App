// Foodi-App/Managers/LeaderboardViewModel.swift
import Foundation
import Combine               // <-- required
import FirebaseFirestore

enum LeaderboardFilter: String, CaseIterable {
    case users = "Users"
    case restaurants = "Restaurants"
    case foodTypes = "Food Types"
}

struct LeaderboardUser: Identifiable {
    var id: String
    var username: String
    var score: Int
    var profilePicURL: String?
}

struct RestaurantRank: Identifiable {
    var id: String        // restaurant name
    var name: String
    var count: Int        // number of posts
}

struct FoodTypeRank: Identifiable {
    var id: String        // food type name
    var name: String
    var count: Int        // number of posts
}

final class LeaderboardViewModel: ObservableObject {
    @Published var users: [LeaderboardUser] = []
    @Published var restaurantRanks: [RestaurantRank] = []
    @Published var foodTypeRanks: [FoodTypeRank] = []
    
    private let db = Firestore.firestore()

    init() {}
    
    func fetchOnce(limit: Int = 50) {
        print("LB ▶︎ starting fetch")
        
        db.collection("users")
            .order(by: "score", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snap, err in
                if let err = err {
                    print("LB ✖︎ error:", err)
                    self?.loadRestaurantAndFoodTypes()
                    return
                }
                
                let docs = snap?.documents ?? []
                let list = docs.map { d -> LeaderboardUser in
                    let x = d.data()
                    let u = LeaderboardUser(
                        id: d.documentID,
                        username: x["username"] as? String ?? "Unknown",
                        score: x["score"] as? Int ?? 0,
                        profilePicURL: x["profilePicURL"] as? String
                    )
                    return u
                }
                
                print("LB ✓ fetched \(list.count) users (ordered):")
                for (i, u) in list.enumerated() {
                    print("  #\(i+1) \(u.username) score=\(u.score) id=\(u.id)")
                }
                
                DispatchQueue.main.async {
                    self?.users = list
                }
                
                self?.loadRestaurantAndFoodTypes()
            }
    }
    
    // MARK: - Restaurants & Food Types
    
    private func loadRestaurantAndFoodTypes() {
        db.collection("posts").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("LB ✖︎ error loading posts:", error)
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            var restaurantCounts: [String: Int] = [:]
            var foodTypeCounts: [String: Int] = [:]
            
            for doc in documents {
                let data = doc.data()
                
                let restaurant = (data["restaurant"] as? String ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let foodType = (data["foodType"] as? String ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !restaurant.isEmpty {
                    restaurantCounts[restaurant, default: 0] += 1
                }
                if !foodType.isEmpty {
                    foodTypeCounts[foodType, default: 0] += 1
                }
            }
            
            let restaurantRanks = restaurantCounts
                .map { (name, count) in
                    RestaurantRank(id: name, name: name, count: count)
                }
                .sorted { $0.count > $1.count }
            
            let foodTypeRanks = foodTypeCounts
                .map { (name, count) in
                    FoodTypeRank(id: name, name: name, count: count)
                }
                .sorted { $0.count > $1.count }
            
            DispatchQueue.main.async {
                self?.restaurantRanks = restaurantRanks
                self?.foodTypeRanks = foodTypeRanks
            }
        }
    }
}
