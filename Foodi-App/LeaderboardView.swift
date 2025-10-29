import SwiftUI

struct LeaderboardView: View {
    @StateObject private var vm = LeaderboardViewModel()

    var body: some View {
        List {
            ForEach(vm.users.indices, id: \.self) { i in
                let u = vm.users[i]
                HStack {
                    Text("#\(i + 1)")
                        .font(.headline)
                        .frame(width: 32, alignment: .trailing)

                    Text(u.username).bold()
                    Spacer()

                    Text("\(u.score) pts")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Leaderboard")
        .onAppear { vm.fetchOnce() }
    }
}

