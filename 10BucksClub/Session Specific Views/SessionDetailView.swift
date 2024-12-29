import SwiftUI
import SwiftData

enum DetailSegment: String, CaseIterable, Identifiable {
    case teams = "Teams"
    case draws = "Draws"
    case results = "Results"
    case seasonalResults = "Season"
    
    var id: String { rawValue }
}

struct SessionDetailView: View {
    let session: Session

    @State private var selectedSegment: DetailSegment = .teams

    var body: some View {
        VStack {
            Picker("View", selection: $selectedSegment) {
                ForEach(DetailSegment.allCases) { segment in
                    Text(segment.rawValue).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])

            switch selectedSegment {
            case .teams:
                TeamsView(session: session)
            case .draws:
                DrawsView(session: session)
            case .results:
                ResultsView(session: session)
            case .seasonalResults:
                SeasonalResultsView(seasonNumber: session.seasonNumber)
            }

            Spacer()
        }
        .navigationTitle("Season \(session.seasonNumber) Session \(session.sessionNumber)")
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

        return SessionDetailView(session: session)
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
