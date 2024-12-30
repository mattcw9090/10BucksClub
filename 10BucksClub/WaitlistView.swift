import SwiftUI
import SwiftData

struct WaitlistView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(
        filter: #Predicate<Player> { player in
            player.statusRawValue == "On the Waitlist"
        },
        sort: [SortDescriptor(\.waitlistPosition, order: .forward)]
    )
    private var waitlistPlayers: [Player]

    var body: some View {
        NavigationView {
            List {
                ForEach(waitlistPlayers) { player in
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.blue)
    
                        VStack(alignment: .leading) {
                            Text(player.name)
                                .font(.headline)
                            if let pos = player.waitlistPosition {
                                Text("Position: \(pos)")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                    .swipeActions(edge: .trailing) {
                        // Remove from Waitlist Action
                        Button(role: .destructive) {
                            removeFromWaitlist(player)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                        
                        // Move to Bottom Action
                        Button {
                            moveToBottom(player)
                        } label: {
                            Label("Move to Bottom", systemImage: "arrow.down")
                        }
                        .tint(.blue)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Waitlist")
            .alert("Operation Failed", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Alert Properties
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    /// Removes a player from the waitlist and updates other players' positions.
    private func removeFromWaitlist(_ player: Player) {
        guard let removedPosition = player.waitlistPosition else { return }
        
        // Update player's status and remove waitlistPosition
        player.status = .notInSession
        player.waitlistPosition = nil
        
        // Find all players below the removed player in the waitlist
        let affectedPlayers = waitlistPlayers.filter { ($0.waitlistPosition ?? 0) > removedPosition }
        
        // Decrement waitlistPosition for affected players
        for affectedPlayer in affectedPlayers {
            if let currentPos = affectedPlayer.waitlistPosition {
                affectedPlayer.waitlistPosition = currentPos - 1
            }
        }
        
        // Save changes to the context
        do {
            try modelContext.save()
        } catch {
            alertMessage = "Failed to remove player from waitlist: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    /// Moves a player to the bottom of the waitlist by updating their waitlistPosition
    /// and adjusting the positions of other players accordingly.
    private func moveToBottom(_ player: Player) {
        guard let currentPosition = player.waitlistPosition else { return }
        
        // Find all players below the current player
        let playersBelow = waitlistPlayers.filter { ($0.waitlistPosition ?? 0) > currentPosition }
        
        // Decrement waitlistPosition for players below the moving player
        for belowPlayer in playersBelow {
            if let pos = belowPlayer.waitlistPosition {
                belowPlayer.waitlistPosition = pos - 1
            }
        }
        
        // Determine the new maximum waitlistPosition after shifting
        let newMaxPosition = waitlistPlayers.count
        
        // Assign the moving player to the new maximum position
        player.waitlistPosition = newMaxPosition
        
        // Save changes to the context
        do {
            try modelContext.save()
        } catch {
            alertMessage = "Failed to move player to bottom of waitlist: \(error.localizedDescription)"
            showingAlert = true
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
        context.insert(Player(name: "Charlie", status: .onWaitlist, waitlistPosition: 3))
        context.insert(Player(name: "Denise", status: .onWaitlist, waitlistPosition: 1))
        context.insert(Player(name: "Eve", status: .onWaitlist, waitlistPosition: 4))

        return WaitlistView()
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
