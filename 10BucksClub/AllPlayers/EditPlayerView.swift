import SwiftUI
import SwiftData

struct EditPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var player: Player

    @Query(sort: [SortDescriptor<Player>(\.name, order: .forward)])
    private var allPlayers: [Player]

    private var waitlistPlayers: [Player] {
        allPlayers.filter { $0.status == .onWaitlist }
                  .sorted { ($0.waitlistPosition ?? 0) < ($1.waitlistPosition ?? 0) }
    }

    // Temporary state variables for editing
    @State private var editedName: String = ""
    @State private var editedStatus: Player.PlayerStatus = .notInSession

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
                    TextField("Name", text: $editedName)

                    Picker("Status", selection: $editedStatus) {
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
                    }
                    .disabled(editedName.isEmpty)
                }
            }
            .onAppear {
                // Initialize temporary variables with current player data
                editedName = player.name
                editedStatus = player.status
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

    private func saveChanges() {
        // Ensure unique name validation
        if allPlayers.contains(where: { $0.name == editedName && $0.id != player.id }) {
            alertMessage = "A player with the name '\(editedName)' already exists. Please choose a different name."
            showingAlert = true
            return
        }
        
        // Ensure player is unassigned if changing from .playing
        if player.status == .playing && editedStatus != .playing {
            if let sessionParticipants = sessionParticipants,
               sessionParticipants.contains(where: { $0.player == player && $0.team != nil }) {
                alertMessage = "Please unassign the player from the team before changing their status."
                showingAlert = true
                return
            }
        }
        
        switch (player.status, editedStatus) {
        
        case (.notInSession, .onWaitlist):
            player.waitlistPosition = (waitlistPlayers.compactMap { $0.waitlistPosition }.max() ?? 0) + 1
            
        case (.onWaitlist, .notInSession):
            guard let removedPosition = player.waitlistPosition else { return }
            player.waitlistPosition = nil
            waitlistPlayers
                .filter { ($0.waitlistPosition ?? 0) > removedPosition }
                .forEach { $0.waitlistPosition? -= 1 }
            
        case (.notInSession, .playing), (.onWaitlist, .playing):
            guard let session = latestSession, sessionParticipants != nil else {
                alertMessage = "No active session to move the player into."
                showingAlert = true
                return
            }
            
            if player.status == .onWaitlist, let removedPosition = player.waitlistPosition {
                player.status = .playing
                player.waitlistPosition = nil
                waitlistPlayers
                    .filter { ($0.waitlistPosition ?? 0) > removedPosition }
                    .forEach { $0.waitlistPosition? -= 1 }
            }
            
            modelContext.insert(SessionParticipants(session: session, player: player))
            
        case (.playing, .notInSession), (.playing, .onWaitlist):
            guard let session = latestSession, let sessionParticipants = sessionParticipants else {
                alertMessage = "No active session to remove the player from."
                showingAlert = true
                return
            }
            
            // Ensure player is unassigned before status change
            if sessionParticipants.contains(where: { $0.player == player && $0.team != nil }) {
                alertMessage = "Please unassign the player from the team before changing their status."
                showingAlert = true
                return
            }
            
            // Proceed with removing the player from the session
            if let participantRecord = sessionParticipants.first(where: { $0.player == player && $0.session == session }) {
                modelContext.delete(participantRecord)
            } else {
                alertMessage = "Player is not found in the current session participants."
                showingAlert = true
                return
            }
            
            if editedStatus == .onWaitlist {
                player.waitlistPosition = (waitlistPlayers.compactMap { $0.waitlistPosition }.max() ?? 0) + 1
            }
            
        default:
            break
        }
        
        // Apply changes from temporary variables to the player
        player.name = editedName
        player.status = editedStatus
        
        // Save the context to persist changes
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = "Failed to save changes: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

#Preview {
    let schema = Schema([Player.self, Season.self, Session.self, SessionParticipants.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])

        // Insert Mock Data
        let context = mockContainer.mainContext
        let playerToEdit = Player(name: "Charlie", status: .playing)
        context.insert(Player(name: "Alice", status: .playing))
        context.insert(Player(name: "Bob", status: .onWaitlist, waitlistPosition: 2))
        context.insert(playerToEdit)
        context.insert(Player(name: "Denise", status: .onWaitlist, waitlistPosition: 1))
        let season = Season(seasonNumber: 1)
        context.insert(season)
        let session = Session(sessionNumber: 1, season: season)
        context.insert(session)
        let participant = SessionParticipants(session: session, player: playerToEdit, team: .Red)
        context.insert(participant)

        return EditPlayerView(player: playerToEdit)
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
