//
//  NotificationsView.swift
//  Foodi
//
//  Created by Alhasan Alnouri on 11/25/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Notification Model
struct AppNotification: Identifiable {
    let id: String
    let type: String           // "like", "comment", "follow"
    let fromUserId: String
    let fromUsername: String
    let postId: String?
    let commentText: String?
    let timestamp: Date
}

// MARK: - Notifications View
struct NotificationsView: View {
    @State private var notifications: [AppNotification] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading notifications...")
                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if notifications.isEmpty {
                    Text("No notifications yet.")
                        .foregroundColor(.secondary)
                } else {
                    List(notifications) { notif in
                        if notif.type == "follow" {
                            NavigationLink {
                                UserProfileView(userId: notif.fromUserId)
                            } label: {
                                NotificationRowView(notification: notif)
                            }
                        } else {
                            NotificationRowView(notification: notif)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Notifications")
            .onAppear {
                loadNotifications()
                markAllNotificationsAsRead()
            }
        }
    }
    
    // MARK: - Load notifications for current user
    private func loadNotifications() {
        guard let uid = Auth.auth().currentUser?.uid else {
            notifications = []
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        db.collection("users")
            .document(uid)
            .collection("notifications")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                isLoading = false
                
                if let error = error {
                    errorMessage = "Failed to load notifications: \(error.localizedDescription)"
                    notifications = []
                    return
                }
                
                guard let docs = snapshot?.documents else {
                    notifications = []
                    return
                }
                
                notifications = docs.compactMap { doc in
                    let data = doc.data()
                    return AppNotification(
                        id: doc.documentID,
                        type: data["type"] as? String ?? "",
                        fromUserId: data["fromUserId"] as? String ?? "",
                        fromUsername: data["fromUsername"] as? String ?? "Someone",
                        postId: data["postId"] as? String,
                        commentText: data["commentText"] as? String,
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
            }
    }
    
    // MARK: - Mark notifications as read
    private func markAllNotificationsAsRead() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let notifRef = db.collection("users")
            .document(uid)
            .collection("notifications")

        notifRef.whereField("read", isEqualTo: false)
            .getDocuments { snap, _ in
                snap?.documents.forEach { doc in
                    doc.reference.updateData(["read": true])
                }
            }
    }
}

// MARK: - Row View
struct NotificationRowView: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Placeholder avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(notification.fromUsername.prefix(1)).uppercased())
                        .font(.headline)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notificationMessage)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(notification.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
    
    private var notificationMessage: String {
        switch notification.type {
        case "like":
            return "\(notification.fromUsername) liked your post."
        case "comment":
            if let text = notification.commentText, !text.isEmpty {
                return "\(notification.fromUsername) commented: \"\(text)\""
            } else {
                return "\(notification.fromUsername) commented on your post."
            }
        case "follow":
            return "\(notification.fromUsername) started following you."
        default:
            return "\(notification.fromUsername) interacted with you."
        }
    }
}
