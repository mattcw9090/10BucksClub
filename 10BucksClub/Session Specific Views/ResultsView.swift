import SwiftUI
import SwiftData

struct ResultsView: View {
    let session: Session

    @Query private var doublesMatches: [DoublesMatch]
    @Query private var sessionParticipants: [SessionParticipants]

    init(session: Session) {
        self.session = session
        let sessionID = session.uniqueIdentifier

        // Query all DoublesMatches for this session
        self._doublesMatches = Query(
            filter: #Predicate<DoublesMatch> { match in
                match.session.uniqueIdentifier == sessionID
            }
        )

        // Query all Participants for this session
        self._sessionParticipants = Query(
            filter: #Predicate<SessionParticipants> { participant in
                participant.session.uniqueIdentifier == sessionID
            }
        )
    }

    var body: some View {
        // 1) Only consider matches that are "complete"
        let completedMatches = doublesMatches.filter { $0.isComplete }

        // 2) Calculate total Red/Black team scores from completed matches
        let totalRedScore = completedMatches.reduce(0) { partialResult, match in
            partialResult + match.redTeamScoreFirstSet + match.redTeamScoreSecondSet
        }

        let totalBlackScore = completedMatches.reduce(0) { partialResult, match in
            partialResult + match.blackTeamScoreFirstSet + match.blackTeamScoreSecondSet
        }

        // 3) Calculate each participant’s net contribution from completed matches
        let participantScores = sessionParticipants.map { participant -> (String, Int) in
            let relevantMatches = completedMatches.filter { match in
                match.player1.id == participant.player.id ||
                match.player2.id == participant.player.id ||
                match.player3.id == participant.player.id ||
                match.player4.id == participant.player.id
            }

            let netScore = relevantMatches.reduce(0) { sum, match in
                let blackMinusRed =
                    (match.blackTeamScoreFirstSet + match.blackTeamScoreSecondSet)
                  - (match.redTeamScoreFirstSet   + match.redTeamScoreSecondSet)

                let diff = (participant.team == .Black)
                    ? blackMinusRed
                    : -blackMinusRed

                return sum + diff
            }

            return (participant.player.name, netScore)
        }

        VStack(spacing: 20) {
            // --- Team Scores Display ---
            VStack {
                Text("Team Scores")
                    .font(.headline)
                    .padding(.vertical)

                HStack {
                    // Red Team
                    VStack {
                        Text("Red Team")
                            .font(.subheadline)
                        Text("\(totalRedScore)")
                            .font(.title)
                            .foregroundColor(.red)
                    }

                    Spacer()

                    // Black Team
                    VStack {
                        Text("Black Team")
                            .font(.subheadline)
                        Text("\(totalBlackScore)")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                }
                .padding()
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()

            // --- Player Net Contributions ---
            VStack(alignment: .leading) {
                Text("Player's Net Score Differences")
                    .font(.headline)
                    .padding(.bottom, 10)

                List(participantScores, id: \.0) { (playerName, netScore) in
                    SessionResultsRowView(playerName: playerName, playerScore: netScore)
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
    let schema = Schema([
        Season.self,
        Session.self,
        Player.self,
        SessionParticipants.self,
        DoublesMatch.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = mockContainer.mainContext

        // 1) Create a Season & Session
        let season = Season(seasonNumber: 4)
        context.insert(season)

        let session = Session(sessionNumber: 5, season: season)
        context.insert(session)

        // 2) Create some Players
        let playerA = Player(name: "Shin")
        let playerB = Player(name: "Suan Sian Foo")
        let playerC = Player(name: "Chris Fan")
        let playerD = Player(name: "CJ")
        let playerE = Player(name: "Nicson Hiew")
        let playerF = Player(name: "Issac Lai")

        context.insert(playerA)
        context.insert(playerB)
        context.insert(playerC)
        context.insert(playerD)
        context.insert(playerE)
        context.insert(playerF)

        // 3) Assign players to teams via SessionParticipants
        let participantsA = SessionParticipants(session: session, player: playerA, team: .Black)
        let participantsB = SessionParticipants(session: session, player: playerB, team: .Black)
        let participantsC = SessionParticipants(session: session, player: playerC, team: .Red)
        let participantsD = SessionParticipants(session: session, player: playerD, team: .Red)
        let participantsE = SessionParticipants(session: session, player: playerE, team: .Black)
        let participantsF = SessionParticipants(session: session, player: playerF, team: .Red)

        context.insert(participantsA)
        context.insert(participantsB)
        context.insert(participantsC)
        context.insert(participantsD)
        context.insert(participantsE)
        context.insert(participantsF)

        // 4) Create some DoublesMatch objects
        let match1 = DoublesMatch(
            session: session,
            waveNumber: 1,
            player1: playerA,
            player2: playerB,
            player3: playerC,
            player4: playerD,
            redTeamScoreFirstSet: 21,
            blackTeamScoreFirstSet: 15,
            isComplete: true
        )
        let match2 = DoublesMatch(
            session: session,
            waveNumber: 1,
            player1: playerE,
            player2: playerF,
            player3: playerC,
            player4: playerD,
            isComplete: false
        )
        let match3 = DoublesMatch(
            session: session,
            waveNumber: 2,
            player1: playerB,
            player2: playerA,
            player3: playerC,
            player4: playerD,
            redTeamScoreFirstSet: 18,
            blackTeamScoreFirstSet: 22,
            isComplete: true
        )
        context.insert(match1)
        context.insert(match2)
        context.insert(match3)

        return ResultsView(session: session)
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
