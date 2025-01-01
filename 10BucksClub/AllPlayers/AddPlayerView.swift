import SwiftUI
import SwiftData

struct AddPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var status: Player.PlayerStatus = .notInSession
    
    @Query(sort: [SortDescriptor<Player>(\.name, order: .forward)])
    private var allPlayers: [Player]

    private var waitlistPlayers: [Player] {
        allPlayers.filter { $0.status == .onWaitlist }
                  .sorted { ($0.waitlistPosition ?? 0) < ($1.waitlistPosition ?? 0) }
    }

    // All seasons query
    @Query(
        sort: [SortDescriptor<Season>(\.seasonNumber, order: .reverse)]
    )
    private var allSeasons: [Season]

    // All sessions query
    @Query(
        sort: [SortDescriptor<Session>(\.sessionNumber, order: .reverse)]
    )
    private var allSessions: [Session]

    // All session participants query
    @Query
    private var allParticipants: [SessionParticipants]

    // Computed Properties
    private var latestSeason: Season? {
        allSeasons.first
    }

    private var latestSession: Session? {
        guard let season = latestSeason else { return nil }
        return allSessions.first { $0.season == season }
    }

    private var sessionParticipants: [SessionParticipants]? {
        guard let session = latestSession else { return nil }
        return allParticipants.filter { $0.session == session }
    }

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
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Alert Properties
    @State private var showingAlert = false
    @State private var alertMessage = ""

    private func addPlayer() {
        // Ensure unique name validation
        if allPlayers.contains(where: { $0.name == name }) {
            alertMessage = "A player with the name '\(name)' already exists. Please choose a different name."
            showingAlert = true
            return
        }
        
        let newPlayer = Player(name: name, status: status)

        // Add player to the waitlist if status is .onWaitlist
        if status == .onWaitlist {
            let nextPosition = (waitlistPlayers.compactMap { $0.waitlistPosition }.max() ?? 0) + 1
            newPlayer.waitlistPosition = nextPosition
        }
        // Add player to the current session if status is .playing
        else if status == .playing {
            guard let session = latestSession else {
                alertMessage = "No active session exists to add the player."
                showingAlert = true
                return
            }

            let sessionParticipantsRecord = SessionParticipants(session: session, player: newPlayer)
            modelContext.insert(sessionParticipantsRecord)
        }

        modelContext.insert(newPlayer)

        do {
            try modelContext.save()
        } catch {
            alertMessage = "Failed to save player: \(error.localizedDescription)"
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
        context.insert(Player(name: "Charlie", status: .notInSession))
        context.insert(Player(name: "Denise", status: .onWaitlist, waitlistPosition: 1))

        return AddPlayerView()
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
