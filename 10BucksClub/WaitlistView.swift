import SwiftUI
import SwiftData

struct WaitlistView: View {
    @Environment(\.modelContext) private var modelContext

    // Waitlist query
    @Query(
        filter: #Predicate<Player> { player in
            player.statusRawValue == "On the Waitlist"
        },
        sort: [SortDescriptor<Player>(\.waitlistPosition, order: .forward)]
    )
    private var waitlistPlayers: [Player]

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
            VStack {
                // Display Latest Season
                if let season = latestSeason {
                    Text("Latest Season: \(season.seasonNumber)")
                        .font(.headline)
                        .padding()
                } else {
                    Text("No active seasons.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                }

                // Display Latest Session
                if let session = latestSession {
                    Text("Latest Session: \(session.sessionNumber)")
                        .font(.headline)
                        .padding()
                } else {
                    Text("No active sessions.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                }

                // Display Participants of the Latest Session
                if let participants = sessionParticipants {
                    if participants.isEmpty {
                        Text("No participants in the latest session.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        List(participants, id: \.compositeKey) { participant in
                            Text("Player: \(participant.player.name), Team: \(participant.team?.rawValue ?? "Unassigned")")
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                } else {
                    Text("No session exists.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                }


                // Waitlist Section
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
                            // Move to Current Session Action
                            Button {
                                moveToCurrentSession(player)
                            } label: {
                                Label("Move to Current Session", systemImage: "sportscourt")
                            }

                            // Move to Bottom Action
                            Button {
                                moveToBottom(player)
                            } label: {
                                Label("Move to Bottom", systemImage: "arrow.down")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .leading) {
                            // Remove from Waitlist Action
                            Button {
                                removeFromWaitlist(player)
                            } label: {
                                Label("Remove from Waitlist", systemImage: "minus.circle")
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Waitlist")
            }
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

    // MARK: - Helper Methods

    /// Removes a player from the waitlist and updates other players' positions.
    private func moveToCurrentSession(_ player: Player) {
        // Ensure there is an active session before making any changes
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

        // Save changes to the model context
        do {
            try modelContext.save()
        } catch {
            alertMessage = "Failed to move player to current session: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    /// Moves a player to the bottom of the waitlist by updating their waitlistPosition.
    private func moveToBottom(_ player: Player) {
        guard let currentPosition = player.waitlistPosition else { return }

        let playersBelow = waitlistPlayers.filter { ($0.waitlistPosition ?? 0) > currentPosition }
        for belowPlayer in playersBelow {
            if let pos = belowPlayer.waitlistPosition {
                belowPlayer.waitlistPosition = pos - 1
            }
        }

        let newMaxPosition = waitlistPlayers.count
        player.waitlistPosition = newMaxPosition

        do {
            try modelContext.save()
        } catch {
            alertMessage = "Failed to move player to bottom of waitlist: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    /// Removes a player from the waitlist
    private func removeFromWaitlist(_ player: Player) {
        guard let removedPosition = player.waitlistPosition else { return }
        
        // Update the player's status and remove from waitlist
        player.status = .notInSession
        player.waitlistPosition = nil
        
        // Adjust positions of remaining players in the waitlist
        let affectedPlayers = waitlistPlayers.filter { ($0.waitlistPosition ?? 0) > removedPosition }
        for affectedPlayer in affectedPlayers {
            if let currentPos = affectedPlayer.waitlistPosition {
                affectedPlayer.waitlistPosition = currentPos - 1
            }
        }
        
        // Save changes to the model context
        do {
            try modelContext.save()
        } catch {
            alertMessage = "Failed to remove player from waitlist: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

#Preview {
    let schema = Schema([Player.self, Season.self, Session.self, SessionParticipants.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])

        let context = mockContainer.mainContext
        let season1 = Season(seasonNumber: 1)
        context.insert(season1)
        let season2 = Season(seasonNumber: 2)
        context.insert(season2)
        context.insert(Session(sessionNumber: 1, season: season2))
        context.insert(Session(sessionNumber: 2, season: season1))
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
