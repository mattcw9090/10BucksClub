import SwiftUI
import SwiftData

struct SeasonalResultsView: View {
    let seasonNumber: Int

    // MARK: - Queries

    @Query private var seasonSessions: [Session]
    @Query private var allParticipants: [SessionParticipants]
    @Query private var allMatches: [DoublesMatch]

    // MARK: - Initialization

    init(seasonNumber: Int) {
        self.seasonNumber = seasonNumber

        self._seasonSessions = Query(
            filter: #Predicate<Session> { $0.seasonNumber == seasonNumber }
        )

        self._allParticipants = Query(
            filter: #Predicate<SessionParticipants> { $0.session.seasonNumber == seasonNumber }
        )

        self._allMatches = Query(
            filter: #Predicate<DoublesMatch> { $0.session.seasonNumber == seasonNumber }
        )
    }

    // MARK: - Computed Properties

    private var aggregatedPlayers: [
        (player: Player, sessionCount: Int, matchCount: Int, averageScore: Double)
    ] {
        var playerStats: [UUID: (player: Player, sessionsAttended: Set<Int>, totalNet: Int, matchCount: Int)] = [:]

        // 1) Record sessions attended by each player
        allParticipants.forEach { participant in
            let pid = participant.player.id
            let sNumber = participant.session.sessionNumber

            if var stats = playerStats[pid] {
                stats.sessionsAttended.insert(sNumber)
                playerStats[pid] = stats
            } else {
                playerStats[pid] = (
                    participant.player,
                    [sNumber],
                    0,
                    0
                )
            }
        }

        // 2) Filter only complete matches
        let completedMatches = allMatches.filter { $0.isComplete }

        // 3) Aggregate net scores from each match
        completedMatches.forEach { match in
            let blackMinusRed = (match.blackTeamScoreFirstSet + match.blackTeamScoreSecondSet) -
                                (match.redTeamScoreFirstSet + match.redTeamScoreSecondSet)

            let playersInMatch = [match.player1, match.player2, match.player3, match.player4]

            playersInMatch.forEach { matchPlayer in
                guard let participant = allParticipants.first(where: {
                    $0.player.id == matchPlayer.id &&
                    $0.session.uniqueIdentifier == match.session.uniqueIdentifier
                }) else { return }

                let netScore = (participant.team == .Black) ? blackMinusRed : -blackMinusRed

                if var stats = playerStats[matchPlayer.id] {
                    stats.totalNet += netScore
                    stats.matchCount += 1
                    playerStats[matchPlayer.id] = stats
                } else {
                    playerStats[matchPlayer.id] = (
                        matchPlayer,
                        [],
                        netScore,
                        1
                    )
                }
            }
        }

        // 4) Compute average scores and prepare the final array
        return playerStats.values
            .map { stats -> (Player, Int, Int, Double) in
                let avg = stats.matchCount > 0
                    ? Double(stats.totalNet) / Double(stats.matchCount)
                    : 0.0

                return (
                    stats.player,
                    stats.sessionsAttended.count,
                    stats.matchCount,
                    avg
                )
            }
            .sorted { $0.player.name < $1.player.name }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            List {
                // Header
                HStack {
                    Text("Player")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Sessions")
                        .font(.headline)
                        .frame(width: 80, alignment: .trailing)
                    Text("Matches")
                        .font(.headline)
                        .frame(width: 80, alignment: .trailing)
                    Text("Avg Score")
                        .font(.headline)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.vertical, 10)

                // Rows
                ForEach(aggregatedPlayers, id: \.player.id) { item in
                    HStack {
                        Text(item.player.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(item.sessionCount)")
                            .frame(width: 80, alignment: .trailing)
                        Text("\(item.matchCount)")
                            .frame(width: 80, alignment: .trailing)
                        Text(String(format: "%.1f", item.averageScore))
                            .frame(width: 80, alignment: .trailing)
                    }
                    .padding(.vertical, 5)
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
}

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

        // Create Season
        let season = Season(seasonNumber: 4)
        context.insert(season)

        // Create Sessions
        let sessions = (1...2).map { Session(sessionNumber: $0, season: season) }
        sessions.forEach { context.insert($0) }

        // Create Players
        let playerNames = ["Shin", "Suan", "Chris", "CJ"]
        let players = playerNames.map { Player(name: $0) }
        players.forEach { context.insert($0) }

        // Assign Players to Sessions
        let teamsSession1: [Team] = [.Black, .Red, .Red, .Black]
        let teamsSession2: [Team] = [.Red, .Red, .Black, .Black]

        let participantsSession1 = zip(players, teamsSession1).map {
            SessionParticipants(session: sessions[0], player: $0.0, team: $0.1)
        }
        let participantsSession2 = zip(players, teamsSession2).map {
            SessionParticipants(session: sessions[1], player: $0.0, team: $0.1)
        }

        (participantsSession1 + participantsSession2).forEach { context.insert($0) }

        // Create DoublesMatches
        let matches = [
            DoublesMatch(
                session: sessions[0],
                waveNumber: 1,
                player1: players[0],
                player2: players[1],
                player3: players[2],
                player4: players[3],
                redTeamScoreFirstSet: 21,
                blackTeamScoreFirstSet: 15,
                isComplete: true
            ),
            DoublesMatch(
                session: sessions[1],
                waveNumber: 1,
                player1: players[1],
                player2: players[0],
                player3: players[2],
                player4: players[3],
                isComplete: false
            ),
            DoublesMatch(
                session: sessions[0],
                waveNumber: 2,
                player1: players[1],
                player2: players[0],
                player3: players[2],
                player4: players[3],
                redTeamScoreFirstSet: 18,
                blackTeamScoreFirstSet: 22,
                isComplete: true
            )
        ]
        matches.forEach { context.insert($0) }

        // Display SeasonalResultsView for Season 4
        return SeasonalResultsView(seasonNumber: 4)
            .modelContainer(container)
    } catch {
        fatalError("Preview setup failed: \(error)")
    }
}
