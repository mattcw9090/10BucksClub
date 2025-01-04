import SwiftUI
import SwiftData

struct DrawsView: View {
    let session: Session

    @Query private var allDoublesMatches: [DoublesMatch]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(
                    Dictionary(grouping: allDoublesMatches.filter { $0.session == session }, by: { $0.waveNumber })
                        .keys.sorted(),
                    id: \.self
                ) { wave in
                    WaveView(
                        title: "Wave \(wave)",
                        matches: (Dictionary(grouping: allDoublesMatches.filter { $0.session == session }, by: { $0.waveNumber })[wave] ?? []).map(convertToMatch)
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private func convertToMatch(_ doublesMatch: DoublesMatch) -> Match {
        let totalRed = doublesMatch.redTeamScoreFirstSet + doublesMatch.redTeamScoreSecondSet
        let totalBlack = doublesMatch.blackTeamScoreFirstSet + doublesMatch.blackTeamScoreSecondSet
        let anyPoints = totalRed + totalBlack > 0
        let winningTeam: Team? = totalRed > totalBlack ? .Red : (totalBlack > totalRed ? .Black : nil)
        let score = anyPoints ? "\(doublesMatch.redTeamScoreFirstSet)-\(doublesMatch.blackTeamScoreFirstSet), \(doublesMatch.redTeamScoreSecondSet)-\(doublesMatch.blackTeamScoreSecondSet)" : nil

        return Match(
            name1: doublesMatch.redPlayer1.name,
            name2: doublesMatch.redPlayer2.name,
            name3: doublesMatch.blackPlayer1.name,
            name4: doublesMatch.blackPlayer2.name,
            isCompleted: anyPoints,
            winningTeam: anyPoints ? winningTeam : nil,
            score: score
        )
    }
}

struct WaveView: View {
    let title: String
    let matches: [Match]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .padding(10)

            ForEach(matches) { match in
                MatchView(
                    name1: match.name1,
                    name2: match.name2,
                    name3: match.name3,
                    name4: match.name4,
                    isCompleted: match.isCompleted,
                    winningTeam: match.winningTeam,
                    score: match.score
                )
            }
        }
    }
}

struct Match: Identifiable {
    let id = UUID()
    let name1: String
    let name2: String
    let name3: String
    let name4: String
    let isCompleted: Bool
    let winningTeam: Team?
    let score: String?
}

struct MatchView: View {
    let name1, name2, name3, name4: String
    let isCompleted: Bool
    let winningTeam: Team?
    let score: String?

    @State private var showScore = false
    @State private var inputScore = ""

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text(name1)
                    Text(name2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

                Text("vs").bold()

                VStack(alignment: .trailing, spacing: 10) {
                    Text(name3)
                    Text(name4)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
            }
            .background(isCompleted ? winningTeamColor : Color.clear)
            .border(Color.gray, width: 1)
            .padding(.horizontal)
            .onTapGesture { withAnimation { showScore.toggle() } }

            if showScore {
                if isCompleted, let matchScore = score {
                    Text("Score: \(matchScore)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.top, 5)
                } else {
                    VStack {
                        TextField("Enter score", text: $inputScore)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)

                        Button("Save") {
                            // Update the underlying DoublesMatch in SwiftData
                            print("Score saved: \(inputScore)")
                            showScore = false
                        }
                        .padding(.top, 5)
                    }
                }
            }
        }
    }

    private var winningTeamColor: Color {
        switch winningTeam {
        case .Red: return Color.red.opacity(0.2)
        case .Black: return Color.black.opacity(0.2)
        default: return Color.green.opacity(0.2)
        }
    }
}

// MARK: - Preview with Mock Data

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

        let season = Season(seasonNumber: 4)
        context.insert(season)

        let session = Session(sessionNumber: 5, season: season)
        context.insert(session)

        let players = ["Shin", "Suan Sian Foo", "Chris Fan", "CJ", "Nicson Hiew", "Issac Lai"].map { Player(name: $0) }
        players.forEach { context.insert($0) }

        let match1 = DoublesMatch(
            session: session,
            waveNumber: 1,
            redPlayer1: players[0],
            redPlayer2: players[1],
            blackPlayer1: players[2],
            blackPlayer2: players[3],
            redTeamScoreFirstSet: 21,
            blackTeamScoreFirstSet: 15
        )
        let match2 = DoublesMatch(
            session: session,
            waveNumber: 1,
            redPlayer1: players[4],
            redPlayer2: players[5],
            blackPlayer1: players[2],
            blackPlayer2: players[3]
        )
        let match3 = DoublesMatch(
            session: session,
            waveNumber: 2,
            redPlayer1: players[1],
            redPlayer2: players[0],
            blackPlayer1: players[2],
            blackPlayer2: players[3],
            redTeamScoreFirstSet: 18,
            blackTeamScoreFirstSet: 21
        )
        [match1, match2, match3].forEach { context.insert($0) }

        return DrawsView(session: session)
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
