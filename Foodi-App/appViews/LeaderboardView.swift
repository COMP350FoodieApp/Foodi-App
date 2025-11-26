import SwiftUI

struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = LeaderboardViewModel()
    @State private var selectedFilter: LeaderboardFilter = .users   // .users / .restaurants / .foodTypes

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                header

                VStack(spacing: 12) {
                    filterPicker
                    Divider()
                    contentList
                }
                .background(Color(.systemBackground))
            }
        }
        .onAppear { vm.fetchOnce() }
    }

    // MARK: - Header (similar to HomeView)
    private var header: some View {
        ZStack {
            Color.foodiBlue
                .ignoresSafeArea(edges: .top)

            HStack {
                Text("Leaderboard")
                    .font(.system(size: 34, weight: .bold))   // smaller so it fits in one line
                    .foregroundColor(.white)

                Spacer()

            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .frame(height: 110)   // close to HomeView bar height
    }

    // MARK: - Filter Picker
    private var filterPicker: some View {
        Picker("Leaderboard Filter", selection: $selectedFilter) {
            ForEach(LeaderboardFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Content List
    private var contentList: some View {
        List {
            switch selectedFilter {
            case .users:
                ForEach(vm.users.indices, id: \.self) { i in
                    let u = vm.users[i]
                    leaderboardRow(
                        rank: i + 1,
                        title: u.username,
                        valueText: "\(u.score) pts"
                    )
                }

            case .restaurants:
                ForEach(vm.restaurantRanks.indices, id: \.self) { i in
                    let r = vm.restaurantRanks[i]
                    leaderboardRow(
                        rank: i + 1,
                        title: r.name,
                        valueText: "\(r.count) posts"
                    )
                }

            case .foodTypes:
                ForEach(vm.foodTypeRanks.indices, id: \.self) { i in
                    let f = vm.foodTypeRanks[i]
                    leaderboardRow(
                        rank: i + 1,
                        title: f.name,
                        valueText: "\(f.count) posts"
                    )
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Row Builder
    private func leaderboardRow(rank: Int, title: String, valueText: String) -> some View {
        HStack {
            Text("#\(rank)")
                .font(.headline)
                .frame(width: 32, alignment: .trailing)

            Text(title)
                .bold()

            Spacer()

            Text(valueText)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
}

