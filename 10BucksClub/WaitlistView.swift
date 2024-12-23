import SwiftUI
import SwiftData

struct WaitlistView: View {
    @Query(
        filter: #Predicate<Player> { player in
            player.statusRawValue == "On the Waitlist"
        },
        sort: [SortDescriptor(\.waitlistPosition, order: .forward)]
    )
    private var waitlistPlayers: [Player]

    var body: some View {
        NavigationView {
            List(waitlistPlayers) { player in
                HStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading) {
                        Text(player.name)
                        if let pos = player.waitlistPosition {
                            Text("Position: \(pos)")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }
                .padding(.vertical, 5)
            }
            .navigationTitle("Waitlist")
        }
    }
}


#Preview {
    let schema = Schema([Player.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])

        // Insert Mock Data
        let context = mockContainer.mainContext
        context.insert(Player(name: "Alice", status: .playing))
        context.insert(Player(name: "Bob", status: .onWaitlist, waitlistPosition: 2))
        context.insert(Player(name: "Charlie", status: .notInSession))
        context.insert(Player(name: "Denise", status: .onWaitlist, waitlistPosition: 1))

        return WaitlistView()
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
