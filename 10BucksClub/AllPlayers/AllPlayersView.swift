import SwiftUI
import SwiftData

struct AllPlayersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Player.name) private var allPlayers: [Player]
    
    @Query(
        filter: #Predicate<Player> { player in
            player.statusRawValue == "On the Waitlist"
        },
        sort: [SortDescriptor(\.waitlistPosition, order: .forward)]
    )
    private var waitlistPlayers: [Player]
    
    @State private var showingAddPlayerSheet = false
    @State private var selectedPlayerForEditing: Player?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(allPlayers) { player in
                    Button {
                        selectedPlayerForEditing = player
                    } label: {
                        PlayerRowView(player: player)
                    }
                    .swipeActions(edge: .trailing) {
                        if player.status != .onWaitlist {
                            Button {
                                addToWaitlist(player)
                            } label: {
                                Label("Add to Waitlist", systemImage: "list.bullet")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("All Players")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddPlayerSheet = true
                    } label: {
                        Label("Add Player", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPlayerSheet) {
                AddPlayerView()
            }
            .sheet(item: $selectedPlayerForEditing) { player in
                EditPlayerView(player: player)
            }
        }
    }
    
    // Function to Add Player to Waitlist
    private func addToWaitlist(_ player: Player) {
        player.status = .onWaitlist
        let nextPosition = (waitlistPlayers.map { $0.waitlistPosition ?? 0 }.max() ?? 0) + 1
        player.waitlistPosition = nextPosition
        
        do {
            try modelContext.save()
        } catch {
            print("Error adding player to waitlist: \(error)")
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

        return AllPlayersView()
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
