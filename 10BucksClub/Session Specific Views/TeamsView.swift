import SwiftUI
import SwiftData

struct TeamsView: View {
    let session: Session

    @Query private var allParticipants: [SessionParticipants]
    
    private var participants: [SessionParticipants] {
        allParticipants.filter { $0.session == session }
    }
    
    var body: some View {
        NavigationView {
            List {
                // Red Team Section
                Section(header: teamHeader(text: "Red Team", color: .red)) {
                    ForEach(redTeamMembers, id: \.id) { participant in
                        TeamMemberRow(name: participant.player.name, team: .Red)
                    }
                }

                // Black Team Section
                Section(header: teamHeader(text: "Black Team", color: .black)) {
                    ForEach(blackTeamMembers, id: \.id) { participant in
                        TeamMemberRow(name: participant.player.name, team: .Black)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
    
    // MARK: - Computed Arrays
    
    private var redTeamMembers: [SessionParticipants] {
        participants.filter { $0.team == .Red }
    }

    private var blackTeamMembers: [SessionParticipants] {
        participants.filter { $0.team == .Black }
    }

    // MARK: - UI Helpers

    private func teamHeader(text: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(text)
                .font(.headline)
                .foregroundColor(color)
        }
    }
}

struct TeamMemberRow: View {
    let name: String
    let team: Team

    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundColor(teamColor)
                .frame(width: 30, height: 30)
            Text(name)
                .font(.body)
                .padding(.leading, 5)
        }
        .padding(.vertical, 5)
    }

    private var teamColor: Color {
        switch team {
        case .Red:   return .red
        case .Black: return .black
        }
    }
}

#Preview {
    let schema = Schema([Season.self, Session.self, Player.self, SessionParticipants.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    
    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = mockContainer.mainContext

        // Insert mock data
        let season = Season(seasonNumber: 4)
        context.insert(season)
        let session = Session(sessionNumber: 5, season: season)
        context.insert(session)
        let playerRed  = Player(name: "Shin Hean")
        let playerRed2 = Player(name: "Suan Sian Foo")
        let playerBlk  = Player(name: "Chris Fan")
        let playerBlk2 = Player(name: "CJ")
        context.insert(playerRed)
        context.insert(playerRed2)
        context.insert(playerBlk)
        context.insert(playerBlk2)
        let p1 = SessionParticipants(session: session, player: playerRed,  team: .Red)
        let p2 = SessionParticipants(session: session, player: playerRed2, team: .Red)
        let p3 = SessionParticipants(session: session, player: playerBlk,  team: .Black)
        let p4 = SessionParticipants(session: session, player: playerBlk2, team: .Black)
        context.insert(p1)
        context.insert(p2)
        context.insert(p3)
        context.insert(p4)
        
        return TeamsView(session: session)
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
