import SwiftUI
import SwiftData

struct ResultsView: View {
    let session: Session

    @Query private var doublesMatches: [DoublesMatch]
    @Query private var sessionParticipants: [SessionParticipants]

    init(session: Session) {
        self.session = session
        let sessionID = session.uniqueIdentifier
        self._doublesMatches = Query(filter: #Predicate<DoublesMatch> { $0.session.uniqueIdentifier == sessionID })
        self._sessionParticipants = Query(filter: #Predicate<SessionParticipants> { $0.session.uniqueIdentifier == sessionID })
    }

    // MARK: - Computed Properties

    private var completedMatches: [DoublesMatch] {
        doublesMatches.filter { $0.isComplete }
    }

    private var totalRedScore: Int {
        completedMatches.reduce(0) { $0 + $1.redTeamScoreFirstSet + $1.redTeamScoreSecondSet }
    }

    private var totalBlackScore: Int {
        completedMatches.reduce(0) { $0 + $1.blackTeamScoreFirstSet + $1.blackTeamScoreSecondSet }
    }

    private var participantScores: [(String, Int)] {
        sessionParticipants.map { participant in
            let netScore = completedMatches.filter {
                [$0.redPlayer1.id, $0.redPlayer2.id, $0.blackPlayer1.id, $0.blackPlayer2.id].contains(participant.player.id)
            }.reduce(0) { sum, match in
                let scoreDiff = (match.blackTeamScoreFirstSet + match.blackTeamScoreSecondSet) -
                                (match.redTeamScoreFirstSet + match.redTeamScoreSecondSet)
                return sum + (participant.team == .Black ? scoreDiff : -scoreDiff)
            }
            return (participant.player.name, netScore)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Team Scores
            VStack {
                Text("Team Scores")
                    .font(.headline)
                    .padding(.vertical)

                HStack {
                    VStack {
                        Text("Red Team").font(.subheadline)
                        Text("\(totalRedScore)").font(.title).foregroundColor(.red)
                    }
                    Spacer()
                    VStack {
                        Text("Black Team").font(.subheadline)
                        Text("\(totalBlackScore)").font(.title).foregroundColor(.black)
                    }
                }
                .padding()
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()

            // Player Net Contributions
            VStack(alignment: .leading) {
                Text("Player's Net Score Differences")
                    .font(.headline)
                    .padding(.bottom, 10)

                List(participantScores, id: \.0) { (name, score) in
                    SessionResultsRowView(playerName: name, playerScore: score)
                }
            }
            .padding()
        }
    }
}

// MARK: - SessionResultsRowView

struct SessionResultsRowView: View {
    var playerName: String
    var playerScore: Int

    var body: some View {
        HStack {
            Text(playerName)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(playerScore) points")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Preview

#Preview {
    do {
        let schema = Schema([
            Season.self,
            Session.self,
            Player.self,
            SessionParticipants.self,
            DoublesMatch.self
        ])
        let modelConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfig])
        let context = container.mainContext

        // Create Season & Session
        let season = Season(seasonNumber: 4)
        let session = Session(sessionNumber: 5, season: season)
        context.insert(season)
        context.insert(session)

        // Create Players
        let playerNames = ["Shin", "Suan Sian Foo", "Chris Fan", "CJ", "Nicson Hiew", "Issac Lai"]
        let players = playerNames.map { Player(name: $0) }
        players.forEach { context.insert($0) }

        // Assign Players to Teams
        let teams: [Team] = [.Black, .Black, .Red, .Red, .Black, .Red]
        let participants = zip(players, teams).map { SessionParticipants(session: session, player: $0.0, team: $0.1) }
        participants.forEach { context.insert($0) }

        // Create DoublesMatches
        let matches = [
            DoublesMatch(
                session: session,
                waveNumber: 1,
                redPlayer1: players[0],
                redPlayer2: players[1],
                blackPlayer1: players[2],
                blackPlayer2: players[3],
                redTeamScoreFirstSet: 21,
                blackTeamScoreFirstSet: 15,
                isComplete: true
            ),
            DoublesMatch(
                session: session,
                waveNumber: 1,
                redPlayer1: players[4],
                redPlayer2: players[5],
                blackPlayer1: players[2],
                blackPlayer2: players[3],
                isComplete: false
            ),
            DoublesMatch(
                session: session,
                waveNumber: 2,
                redPlayer1: players[1],
                redPlayer2: players[0],
                blackPlayer1: players[2],
                blackPlayer2: players[3],
                redTeamScoreFirstSet: 18,
                blackTeamScoreFirstSet: 22,
                isComplete: true
            )
        ]
        matches.forEach { context.insert($0) }

        return ResultsView(session: session)
            .modelContainer(container)
    } catch {
        fatalError("Preview setup failed: \(error)")
    }
}
