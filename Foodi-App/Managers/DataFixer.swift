import FirebaseFirestore

class DataFixer {
    static func migratePostsAddingAuthorId() {
        let db = Firestore.firestore()

        db.collection("posts").getDocuments { snapshot, error in
            guard let docs = snapshot?.documents else { return }

            print("🛠 Starting migration for \(docs.count) posts...")

            for doc in docs {
                var data = doc.data()

                // If post already has authorId then skip it
                if data["authorId"] != nil { continue }

                guard let username = data["author"] as? String else { continue }

                // Look up user by username
                db.collection("users")
                    .whereField("username", isEqualTo: username)
                    .getDocuments { userSnap, _ in
                        guard let userDoc = userSnap?.documents.first else { return }
                        let uid = userDoc.documentID

                        doc.reference.updateData(["authorId": uid]) { err in
                            if err == nil {
                                print("Added authorId to post: \(doc.documentID) → \(uid)")
                            }
                        }
                    }
            }
        }
    }
}
