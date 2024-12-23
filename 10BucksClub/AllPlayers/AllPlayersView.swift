import SwiftUI
import SwiftData

struct AllPlayersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Player.name) private var allPlayers: [Player]
    
    @State private var showingAddPlayerSheet = false
    @State private var showingEditPlayerSheet = false
    @State private var selectedPlayerForEditing: Player?

    var body: some View {
        NavigationView {
            List {
                ForEach(allPlayers) { player in
                    Button {
                        // Optionally, you could use a button or a NavigationLink to edit
                        selectedPlayerForEditing = player
                        showingEditPlayerSheet = true
                    } label: {
                        PlayerRowView(player: player)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            deletePlayer(player)
                        } label: {
                            Label("Delete", systemImage: "trash")
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
            // Present the Edit sheet when we have a selected player
            .sheet(item: $selectedPlayerForEditing) { player in
                EditPlayerView(player: player)
            }
        }
    }
    
    private func deletePlayer(_ player: Player) {
        modelContext.delete(player)
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
        context.insert(Player(name: "Bob", status: .onWaitlist, waitlistPosition: 1))
        context.insert(Player(name: "Charlie", status: .notInSession))

        return AllPlayersView()
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
