import SwiftUI
import SwiftData

struct DrawsView: View {
    let session: Session

    @Query private var allDoublesMatches: [DoublesMatch]

    private var relevantMatches: [DoublesMatch] {
        allDoublesMatches.filter { $0.session == session }
    }

    private var waveGroups: [Int: [DoublesMatch]] {
        Dictionary(grouping: relevantMatches) { $0.waveNumber }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Loop through each wave number in ascending order
                ForEach(waveGroups.keys.sorted(), id: \.self) { wave in
                    // Retrieve the matches for this wave
                    let waveMatches = waveGroups[wave] ?? []

                    // Convert the DoublesMatch data to your existing Match struct
                    WaveView(
                        title: "Wave \(wave)",
                        matches: waveMatches.map(convertToMatch)
                    )
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Conversion Helper
    /// Convert a DoublesMatch model instance into your ephemeral Match struct for display.
    private func convertToMatch(_ doublesMatch: DoublesMatch) -> Match {
        let anyPointsScored = (
            doublesMatch.redTeamScoreFirstSet +
            doublesMatch.blackTeamScoreFirstSet +
            doublesMatch.redTeamScoreSecondSet +
            doublesMatch.blackTeamScoreSecondSet
        ) > 0

        let redTotal = doublesMatch.redTeamScoreFirstSet + doublesMatch.redTeamScoreSecondSet
        let blackTotal = doublesMatch.blackTeamScoreFirstSet + doublesMatch.blackTeamScoreSecondSet
        let winningTeam: Team? = redTotal > blackTotal ? .Red : (blackTotal > redTotal ? .Black : nil)

        let scoreString = "\(doublesMatch.redTeamScoreFirstSet)-\(doublesMatch.blackTeamScoreFirstSet), \(doublesMatch.redTeamScoreSecondSet)-\(doublesMatch.blackTeamScoreSecondSet)"

        return Match(
            name1: doublesMatch.player1.name,
            name2: doublesMatch.player2.name,
            name3: doublesMatch.player3.name,
            name4: doublesMatch.player4.name,
            isCompleted: anyPointsScored,
            winningTeam: anyPointsScored ? winningTeam : nil,
            score: anyPointsScored ? scoreString : nil
        )
    }
}

// MARK: - Existing Waves and Match Views

struct WaveView: View {
    let title: String
    let matches: [Match]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 5)

            VStack(spacing: 0) {
                ForEach(matches, id: \.id) { match in
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
    let name1: String
    let name2: String
    let name3: String
    let name4: String
    let isCompleted: Bool
    let winningTeam: Team?
    let score: String?

    @State private var showScore: Bool = false
    @State private var inputScore: String = ""

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text(name1)
                    Text(name2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

                Text("vs")
                    .bold()

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
            .onTapGesture {
                withAnimation {
                    showScore.toggle()
                }
            }

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
                            // In practice, you'd update the underlying DoublesMatch in SwiftData
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

        // Create a Season & Session
        let season = Season(seasonNumber: 4)
        context.insert(season)

        let session = Session(sessionNumber: 5, season: season)
        context.insert(session)

        // Create some Players
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

        // Create some DoublesMatch objects
        let match1 = DoublesMatch(
            session: session,
            waveNumber: 1,
            player1: playerA,
            player2: playerB,
            player3: playerC,
            player4: playerD,
            redTeamScoreFirstSet: 21,
            blackTeamScoreFirstSet: 15
        )
        let match2 = DoublesMatch(
            session: session,
            waveNumber: 1,
            player1: playerE,
            player2: playerF,
            player3: playerC,
            player4: playerD
        )
        let match3 = DoublesMatch(
            session: session,
            waveNumber: 2,
            player1: playerB,
            player2: playerA,
            player3: playerC,
            player4: playerD,
            redTeamScoreFirstSet: 18,
            blackTeamScoreFirstSet: 21
        )
        context.insert(match1)
        context.insert(match2)
        context.insert(match3)

        return DrawsView(session: session)
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
