// File: 10BucksClub/AllPlayers/EditPlayerView.swift

import SwiftUI
import SwiftData

struct EditPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var player: Player

    @Query(
        filter: #Predicate<Player> { player in
            player.statusRawValue == "On the Waitlist"
        },
        sort: [SortDescriptor(\.waitlistPosition, order: .forward)]
    )
    private var waitlistPlayers: [Player]

    // Track the original status to handle status changes
    @State private var originalStatus: Player.PlayerStatus = .notInSession

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Player Details")) {
                    TextField("Name", text: $player.name)
                    
                    Picker("Status", selection: $player.status) {
                        ForEach(Player.PlayerStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.capitalized).tag(status)
                        }
                    }
                }
            }
            .navigationTitle("Edit Player")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(player.name.isEmpty)
                }
            }
            .onAppear {
                // Initialize the original status when the view appears
                originalStatus = player.status
            }
        }
    }

    private func saveChanges() {
        // Handle status change
        if originalStatus != .onWaitlist && player.status == .onWaitlist {
            // Player is being added to the waitlist
            let nextPosition = (waitlistPlayers.compactMap { $0.waitlistPosition }.max() ?? 0) + 1
            player.waitlistPosition = nextPosition
        } else if originalStatus == .onWaitlist && player.status != .onWaitlist {
            // Player is being removed from the waitlist
            if let removedPosition = player.waitlistPosition {
                player.waitlistPosition = nil
                // Decrement waitlist positions for players below the removed position
                let affectedPlayers = waitlistPlayers.filter { ($0.waitlistPosition ?? 0) > removedPosition }
                for var affectedPlayer in affectedPlayers {
                    affectedPlayer.waitlistPosition? -= 1
                }
            }
        }
        // If the player remains on the waitlist and the position is unchanged, do nothing

        // Save the context to persist changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to save changes: \(error.localizedDescription)")
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
        let playerToEdit = Player(name: "Charlie", status: .notInSession)
        context.insert(Player(name: "Alice", status: .playing))
        context.insert(Player(name: "Bob", status: .onWaitlist, waitlistPosition: 2))
        context.insert(playerToEdit)
        context.insert(Player(name: "Denise", status: .onWaitlist, waitlistPosition: 1))

        return EditPlayerView(player: playerToEdit)
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
