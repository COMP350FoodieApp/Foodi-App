// Foodi-App/Managers/LeaderboardViewModel.swift
import Foundation
import Combine               // <-- required
import FirebaseFirestore

struct LeaderboardUser: Identifiable {
    var id: String
    var username: String
    var score: Int
    var profilePicURL: String?
}

final class LeaderboardViewModel: ObservableObject {
    @Published var users: [LeaderboardUser] = []
    private let db = Firestore.firestore()

    init() {}

    func fetchOnce(limit: Int = 50) {
        print("LB ▶︎ starting fetch")
        db.collection("users")
          .order(by: "score", descending: true)
          .limit(to: limit)
          .getDocuments { [weak self] snap, err in
              if let err = err { print("LB ✖︎ error:", err); return }
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
              for (i,u) in list.enumerated() { print("  #\(i+1) \(u.username) score=\(u.score) id=\(u.id)") }
              DispatchQueue.main.async { self?.users = list }
          }
    }

}

