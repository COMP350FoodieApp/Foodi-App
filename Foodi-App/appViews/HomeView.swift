//
//  HomeView.swift
//  Foodi
//
//  Edited by d-rod on 11/11/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - HomeView (2×2 board with one movable hole; drag only; no Combine)
struct HomeView: View {
    @State private var selectedWidget: WidgetType? = nil
    @State private var showPostSheet = false
    @State private var unreadCount: Int = 0
    @State private var showUserSearch = false

    // Persisted layout
    private static let layoutKey = "widgetLayoutJSON"

    // Board config: today we expose 2×2 = 4 slots (one is always empty)
    private static let BOARD_COLUMNS = 2
    private static let BOARD_CAPACITY = 6   // raise to 6, 8, ... for longer column later

    // In-memory items (each carries its absolute board position in 0..<BOARD_CAPACITY)
    @State private var items: [Item]

    // Grid visuals
    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: BOARD_COLUMNS)
    private let spacing: CGFloat = 20

    // Init: load layout or seed defaults (hole starts at last slot)
    init() {
        UserDefaults.standard.removeObject(forKey: Self.layoutKey)
        let defaults: [Item] = [
            Item(kind: .leaderboard, pos: 0),
            Item(kind: .feed,        pos: 1),
            Item(kind: .notifications, pos: 2),
            Item(kind: .map,         pos: 3),
            Item(kind: .saved,       pos: 4)
        ]
        if
            let str = UserDefaults.standard.string(forKey: Self.layoutKey),
            let data = str.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(LayoutState.self, from: data)
        {
            _items = State(initialValue: Self.sanitized(decoded.items))
        } else {
            _items = State(initialValue: defaults)
            Self.persist(defaults)
        }
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                // Render a fixed 0..<BOARD_CAPACITY board.
                LazyVGrid(columns: columns, spacing: spacing) {
                    ForEach(0..<Self.BOARD_CAPACITY, id: \.self) { slot in
                        if let item = item(at: slot) {
                            DraggableCard(
                                item: item,
                                spacing: spacing,
                                onDrop: { translation in
                                    if let to = destination(from: item.pos, translation: translation) {
                                        move(item: item, to: to)
                                    }
                                }
                            ) {
                                card(for: item.kind)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        switch item.kind {
                                        case .feed:        selectedWidget = .feed
                                        case .leaderboard: selectedWidget = .leaderboard
                                        case .notifications: selectedWidget = .notifications
                                        case .map:         selectedWidget = .map
                                        case .saved:       selectedWidget = .saved
                                        }
                                    }
                            }
                        } else {
                            // The HOLE: reserved empty space the user can move widgets into.
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.clear)
                                .frame(width: Frames.small.width, height: Frames.small.height)
                        }
                    }
                }
                .padding(.top, 30)
                .padding(.horizontal)
                .padding(.bottom, 100) // space for FABs
            }

            VStack {
                Spacer()
                HStack {
                    // LEFT BUTTON: Search users
                    Button(action: { 
                        // mimic FloatingSearchUsersButton behavior
                        showUserSearch.toggle()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.foodiBlue)
                                .frame(width: 70, height: 70)
                                .shadow(radius: 5)
                            ZStack {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 26, weight: .semibold))
                                    .offset(x: -3, y: 0)
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .semibold))
                                    .offset(x: 8, y: 4)
                            }
                            .foregroundColor(.white)
                        }
                    }
                    .sheet(isPresented: $showUserSearch) {
                        NavigationStack { UserSearchView() }
                    }

                    Spacer()

                    // RIGHT BUTTON: Create Post
                    Button(action: { showPostSheet.toggle() }) {
                        ZStack {
                            Circle()
                                .fill(Color.foodiBlue)
                                .frame(width: 70, height: 70)
                                .shadow(radius: 5)
                            Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                    }
                    .sheet(isPresented: $showPostSheet) { PostView() }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .fullScreenCover(item: $selectedWidget) { widget in
            WidgetDetailView(type: widget, selectedWidget: $selectedWidget)
        }
        .onChange(of: items) { _, _ in save() } // iOS 17+ signature
        .onAppear {
            listenForUnreadNotifications()
        }
    }

    // MARK: - View content (fixed "small" size for all)
    @ViewBuilder
    private func card(for kind: Kind) -> some View {
        switch kind {
        case .feed:
            VStack(spacing: 10) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.foodiBlue)
                Text("Feed").font(.headline).foregroundColor(.primary)
                Text("See what others are posting")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            .frame(width: Frames.small.width, height: Frames.small.height)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)

        case .leaderboard:
            VStack(spacing: 10) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.yellow)
                Text("Leaderboard").font(.headline).foregroundColor(.primary)
                Text("Top Foodies this week")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            .frame(width: Frames.small.width, height: Frames.small.height)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)

        case .notifications:
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 10) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.red)
                    Text("Notifications").font(.headline).foregroundColor(.primary)
                    Text("See recent activity")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .frame(width: Frames.small.width, height: Frames.small.height)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)

                if unreadCount > 0 {
                    Text("\(unreadCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(6)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .offset(x: -10, y: 10)
                }
            }

        case .map:
            MapWidgetView()
                .disabled(true) // keep widget inert; drag gestures belong to wrapper
                .frame(width: Frames.small.width, height: Frames.small.height)
                .cornerRadius(16)
                .shadow(radius: 3)
                .clipped()
            
        case .saved:
            VStack(spacing: 10) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.black)
                Text("Bookmarks").font(.headline).foregroundColor(.primary)
                Text("Saved for later")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            .frame(width: Frames.small.width, height: Frames.small.height)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
    }

    // MARK: - Board helpers

    private func listenForUnreadNotifications() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("notifications")
            .whereField("read", isEqualTo: false)
            .addSnapshotListener { snap, _ in
                unreadCount = snap?.documents.count ?? 0
            }
    }

    private func item(at slot: Int) -> Item? {
        items.first { $0.pos == slot }
    }

    /// Translate drag distance into a target slot on the board.
    private func destination(from fromPos: Int, translation: CGSize) -> Int? {
        let cols = Self.BOARD_COLUMNS
        let cell = Frames.small
        let dx = Int((translation.width  / (cell.width  + spacing)).rounded())
        let dy = Int((translation.height / (cell.height + spacing)).rounded())
        guard dx != 0 || dy != 0 else { return nil }

        let fromRow = fromPos / cols
        let fromCol = fromPos % cols
        let toRow = fromRow + dy
        let toCol = fromCol + dx
        let toPos = toRow * cols + toCol
        guard (0..<Self.BOARD_CAPACITY).contains(toPos) else { return nil }
        return toPos
    }

    /// Move one item to `to`, shifting other items and keeping exactly one hole.
    private func move(item: Item, to toPos: Int) {
        guard item.pos != toPos else { return }
        var copy = items

        // if the destination is occupied, shift the range toward the origin
        if let _ = copy.firstIndex(where: { $0.pos == toPos }) {
            let fromPos = item.pos
            if fromPos < toPos {
                for j in copy.indices where copy[j].pos > fromPos && copy[j].pos <= toPos {
                    copy[j].pos -= 1
                }
            } else {
                for j in copy.indices where copy[j].pos < fromPos && copy[j].pos >= toPos {
                    copy[j].pos += 1
                }
            }
        }
        if let i = copy.firstIndex(where: { $0.id == item.id }) {
            copy[i].pos = toPos
        }
        items = copy
    }

    private func save() {
        let sanitized = Self.sanitized(items)
        items = sanitized
        Self.persist(sanitized)
    }

    // Ensure positions are unique and within bounds; keep exactly one hole.
    private static func sanitized(_ items: [Item]) -> [Item] {
        var copy = items
        for i in copy.indices {
            copy[i].pos = min(max(0, copy[i].pos), BOARD_CAPACITY - 1)
        }
        var used = Set<Int>()
        for i in copy.indices {
            while used.contains(copy[i].pos) {
                copy[i].pos = (copy[i].pos + 1) % BOARD_CAPACITY
            }
            used.insert(copy[i].pos)
        }
        return copy
    }

    private static func persist(_ items: [Item]) {
        if let data = try? JSONEncoder().encode(LayoutState(items: items)),
           let str  = String(data: data, encoding: .utf8) {
            UserDefaults.standard.set(str, forKey: layoutKey)
        }
    }
}

// MARK: - Local types (scoped to HomeView)
private extension HomeView {
    enum Kind: String, Codable, CaseIterable { case feed, leaderboard, map, notifications, saved }

    struct Item: Identifiable, Codable, Equatable {
        var id: UUID = UUID()       // <-- default id fixes the compile error
        var kind: Kind
        var pos: Int                // absolute board slot (0..<BOARD_CAPACITY)

        init(id: UUID = UUID(), kind: Kind, pos: Int) {
            self.id = id
            self.kind = kind
            self.pos = pos
        }
    }

    struct LayoutState: Codable { var items: [Item] }

    enum Frames {
        static let small = CGSize(width: 180, height: 220)
    }

    /// Drag wrapper (no resize)
    struct DraggableCard<Content: View>: View {
        let item: Item
        let spacing: CGFloat
        let onDrop: (CGSize) -> Void
        let content: () -> Content

        @State private var isDragging = false
        @State private var dragTranslation: CGSize = .zero

        var body: some View {
            content()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.thinMaterial)
                        .shadow(radius: isDragging ? 8 : 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.secondary.opacity(isDragging ? 0.6 : 0.2))
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .scaleEffect(isDragging ? 1.03 : 1.0)
                .offset(dragTranslation)
                .gesture(
                    DragGesture(minimumDistance: 4)
                        .onChanged { value in
                            isDragging = true
                            dragTranslation = value.translation
                        }
                        .onEnded { value in
                            isDragging = false
                            dragTranslation = .zero
                            onDrop(value.translation)
                        }
                )
                .animation(animationStyle, value: isDragging)
        }

        private var animationStyle: Animation {
            if #available(iOS 17.0, *) { return .snappy } else { return .easeInOut(duration: 0.2) }
        }
    }
}

// MARK: - Floating Search Users Button (unchanged)
struct FloatingSearchUsersButton: View {
    @State private var showUserSearch = false

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Button(action: { showUserSearch.toggle() }) {
                    ZStack {
                        Circle()
                            .fill(Color.foodiBlue)
                            .frame(width: 70, height: 70)
                            .shadow(radius: 5)
                        ZStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .offset(x: -3, y: 0)
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .semibold))
                                .offset(x: 8, y: 4)
                        }
                        .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 38)
                .padding(.leading, 15)
                .sheet(isPresented: $showUserSearch) {
                    NavigationStack { UserSearchView() }
                }
                Spacer()
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
