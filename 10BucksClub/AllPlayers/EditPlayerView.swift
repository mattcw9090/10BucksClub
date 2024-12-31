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
                originalStatus = player.status
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
        // Handle status change
        if originalStatus == .notInSession && player.status == .onWaitlist {
            let nextPosition = (waitlistPlayers.compactMap { $0.waitlistPosition }.max() ?? 0) + 1
            player.waitlistPosition = nextPosition
            
        } else if originalStatus == .onWaitlist && player.status == .notInSession {
            guard let removedPosition = player.waitlistPosition else { return }
            player.waitlistPosition = nil
            
            let affectedPlayers = waitlistPlayers.filter { ($0.waitlistPosition ?? 0) > removedPosition }
            for affectedPlayer in affectedPlayers {
                if let currentPos = affectedPlayer.waitlistPosition {
                    affectedPlayer.waitlistPosition = currentPos - 1
                }
            }
            
        } else if originalStatus == .notInSession && player.status == .playing {
            guard let session = latestSession, sessionParticipants != nil else {
                alertMessage = "No active session to move the player into."
                showingAlert = true
                return
            }

            // Add the player to the session's participants without assigning a team
            let sessionParticipantsRecord = SessionParticipants(session: session, player: player)
            modelContext.insert(sessionParticipantsRecord)
            
        } else if originalStatus == .onWaitlist && player.status == .playing {
            guard let session = latestSession, sessionParticipants != nil else {
                alertMessage = "No active session to move the player into."
                showingAlert = true
                return
            }

            guard let removedPosition = player.waitlistPosition else { return }

            // Update the player's status and remove from waitlist
            player.status = .playing
            player.waitlistPosition = nil

            // Adjust positions of remaining players in the waitlist
            let affectedPlayers = waitlistPlayers.filter { ($0.waitlistPosition ?? 0) > removedPosition }
            for affectedPlayer in affectedPlayers {
                if let currentPos = affectedPlayer.waitlistPosition {
                    affectedPlayer.waitlistPosition = currentPos - 1
                }
            }

            // Add the player to the session's participants without assigning a team
            let sessionParticipantsRecord = SessionParticipants(session: session, player: player)
            modelContext.insert(sessionParticipantsRecord)
            
        } else if originalStatus == .playing && player.status == .notInSession {
            guard let session = latestSession, let sessionParticipants = sessionParticipants else {
                alertMessage = "No active session to remove the player from."
                showingAlert = true
                return
            }
            
            // Find the SessionParticipants record for this player and session
            if let participantRecord = sessionParticipants.first(where: { $0.player == player && $0.session == session }) {
                modelContext.delete(participantRecord)
            } else {
                alertMessage = "Player is not found in the current session participants."
                showingAlert = true
            }
            
        } else if originalStatus == .playing && player.status == .onWaitlist {
            guard let session = latestSession, let sessionParticipants = sessionParticipants else {
                alertMessage = "No active session to remove the player from."
                showingAlert = true
                return
            }
            
            // Find the SessionParticipants record for this player and session
            if let participantRecord = sessionParticipants.first(where: { $0.player == player && $0.session == session }) {
                modelContext.delete(participantRecord)
            } else {
                alertMessage = "Player is not found in the current session participants."
                showingAlert = true
                return
            }
            
            let nextPosition = (waitlistPlayers.compactMap { $0.waitlistPosition }.max() ?? 0) + 1
            player.waitlistPosition = nextPosition
        }

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
