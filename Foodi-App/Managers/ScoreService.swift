//
//  ScoreService.swift
//  Foodi
//
//  Created by Tyler Hedberg on 11/6/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class ScoreService {
    static let shared = ScoreService()
    private init() {}
    private let db = Firestore.firestore()

    // Tunable weights
    struct Weights {
        static let post = 10
        static let like = 1
        static let comment = 3
    }

    func bumpOnPostCreated(actorUid: String, completion: ((Error?) -> Void)? = nil) {
        updateScore(for: actorUid, field: "postsCount", points: Weights.post, countDelta: 1, completion: completion)
    }

    func bumpOnLikeDelta(actorUid: String, delta: Int, completion: ((Error?) -> Void)? = nil) {
        guard delta != 0 else { completion?(nil); return }
        updateScore(for: actorUid, field: "likesGiven", points: Weights.like * delta, countDelta: delta, completion: completion)
    }

    func bumpOnCommentAdded(actorUid: String, completion: ((Error?) -> Void)? = nil) {
        updateScore(for: actorUid, field: "commentsCount", points: Weights.comment, countDelta: 1, completion: completion)
    }

    func ensureBaseline(for uid: String, username: String? = nil, completion: ((Error?) -> Void)? = nil) {
        let ref = db.collection("users").document(uid)
        ref.setData([
            "username": username ?? FieldValue.delete(),
            "score": 0,
            "metrics": [
                "postsCount": 0,
                "likesGiven": 0,
                "commentsCount": 0
            ]
        ], merge: true) { err in completion?(err) }
    }

    private func updateScore(for uid: String,
                             field: String,
                             points: Int,
                             countDelta: Int,
                             completion: ((Error?) -> Void)? = nil) {
        let ref = db.collection("users").document(uid)

        db.runTransaction({ (txn, errorPointer) -> Any? in
            do {
                let snap = try txn.getDocument(ref)
                let data = snap.data() ?? [:]
                var metrics = data["metrics"] as? [String: Any] ?? [:]

                let currentScore = data["score"] as? Int ?? 0
                let newScore = max(0, currentScore + points)

                let currentCount = metrics[field] as? Int ?? 0
                metrics[field] = max(0, currentCount + countDelta)

                txn.setData(["score": newScore, "metrics": metrics], forDocument: ref, merge: true)
                return nil
            } catch let err as NSError {
                errorPointer?.pointee = err
                return nil
            }
        }, completion: { _, err in
            completion?(err)
        })
    }
}

