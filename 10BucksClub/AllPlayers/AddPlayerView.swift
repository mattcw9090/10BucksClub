import SwiftUI
import SwiftData

struct AddPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var status: Player.PlayerStatus = .notInSession

    @Query(
        filter: #Predicate<Player> { player in
            player.statusRawValue == "On the Waitlist"
        },
        sort: [SortDescriptor(\.waitlistPosition, order: .forward)]
    )
    private var waitlistPlayers: [Player]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Player Details")) {
                    TextField("Name", text: $name)
                    
                    Picker("Status", selection: $status) {
                        ForEach(Player.PlayerStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.capitalized).tag(status)
                        }
                    }
                }
            }
            .navigationTitle("Add Player")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addPlayer()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func addPlayer() {
        let newPlayer = Player(name: name, status: status)
        
        if status == .onWaitlist {
            let nextPosition = (waitlistPlayers.compactMap { $0.waitlistPosition }.max() ?? 0) + 1
            newPlayer.waitlistPosition = nextPosition
        }
        modelContext.insert(newPlayer)

        do {
            try modelContext.save()
        } catch {
            print("Failed to add player: \(error.localizedDescription)")
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

        return AddPlayerView()
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
