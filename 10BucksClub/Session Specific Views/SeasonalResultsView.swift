import SwiftUI
import SwiftData

struct SeasonalResultsView: View {
    let seasonNumber: Int

    // Query all Sessions for this season
    @Query private var seasonSessions: [Session]

    // Query all SessionParticipants for this season
    @Query private var allParticipants: [SessionParticipants]

    // Query all DoublesMatch for this season
    @Query private var allMatches: [DoublesMatch]

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

    /// For each player:
    ///   - The # of distinct sessions
    ///   - The # of matches played
    ///   - The total net across those matches
    ///   - Their average net score
    private var aggregatedPlayers: [
        (player: Player, sessionCount: Int, matchCount: Int, averageScore: Double)
    ] {
        // Dictionary of stats keyed by Player.id
        // value = (player, sessionsAttended, totalNet, matchCount)
        var playerStats: [UUID: (player: Player, sessionsAttended: Set<Int>, totalNet: Int, matchCount: Int)] = [:]

        // 1) Record which sessions each player attends
        for participant in allParticipants {
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

        // 2) Only consider *complete* matches
        let completedMatches = allMatches.filter { $0.isComplete }

        // 3) Aggregate net scores for each complete match
        for match in completedMatches {
            let blackMinusRed =
                (match.blackTeamScoreFirstSet + match.blackTeamScoreSecondSet)
              - (match.redTeamScoreFirstSet   + match.redTeamScoreSecondSet)

            // The 4 players in this match
            let playersInMatch = [
                match.player1,
                match.player2,
                match.player3,
                match.player4
            ]

            for matchPlayer in playersInMatch {
                // Find the participant record that links this player to this session
                if let sp = allParticipants.first(where: { p in
                    p.player.id == matchPlayer.id &&
                    p.session.uniqueIdentifier == match.session.uniqueIdentifier
                }) {
                    let netScore = (sp.team == .Black) ? blackMinusRed : -blackMinusRed

                    if var stats = playerStats[matchPlayer.id] {
                        stats.totalNet += netScore
                        stats.matchCount += 1
                        playerStats[matchPlayer.id] = stats
                    } else {
                        // Fallback if we didn't have the player in the dictionary yet
                        playerStats[matchPlayer.id] = (
                            matchPlayer,
                            [],
                            netScore,
                            1
                        )
                    }
                }
            }
        }

        // 4) Convert dictionary -> array and compute average
        let results = playerStats.values.map { stats -> (Player, Int, Int, Double) in
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
        // Sort by name, or however you like
        .sorted { $0.0.name < $1.0.name }

        return results
    }

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
    let schema = Schema([
        Season.self,
        Session.self,
        Player.self,
        SessionParticipants.self,
        DoublesMatch.self // Include if needed, but not strictly necessary if we’re only counting sessions attended
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    
    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = mockContainer.mainContext
        
        // Create a season
        let season = Season(seasonNumber: 4)
        context.insert(season)
        
        // Create two sessions for that season
        let session1 = Session(sessionNumber: 1, season: season)
        let session2 = Session(sessionNumber: 2, season: season)
        context.insert(session1)
        context.insert(session2)

        // Create some players
        let shin = Player(name: "Shin")
        let suan = Player(name: "Suan")
        let chris = Player(name: "Chris")
        let cj = Player(name: "CJ")
        context.insert(shin)
        context.insert(suan)
        context.insert(chris)
        context.insert(cj)

        // Assign players to session 1
        context.insert(SessionParticipants(session: session1, player: shin, team: .Black))
        context.insert(SessionParticipants(session: session1, player: suan, team: .Red))
        context.insert(SessionParticipants(session: session1, player: chris, team: .Red))
        context.insert(SessionParticipants(session: session1, player: cj, team: .Black))
        
        // Assign players to session 2
        context.insert(SessionParticipants(session: session2, player: shin, team: .Red))
        context.insert(SessionParticipants(session: session2, player: suan, team: .Red))
        context.insert(SessionParticipants(session: session2, player: chris, team: .Black))
        context.insert(SessionParticipants(session: session2, player: cj, team: .Black))
        
        let match1 = DoublesMatch(
            session: session1,
            waveNumber: 1,
            player1: shin,
            player2: suan,
            player3: chris,
            player4: cj,
            redTeamScoreFirstSet: 21,
            blackTeamScoreFirstSet: 15,
            isComplete: true
        )
        let match2 = DoublesMatch(
            session: session2,
            waveNumber: 1,
            player1: suan,
            player2: shin,
            player3: chris,
            player4: cj
        )
        let match3 = DoublesMatch(
            session: session1,
            waveNumber: 2,
            player1: suan,
            player2: shin,
            player3: chris,
            player4: cj,
            redTeamScoreFirstSet: 18,
            blackTeamScoreFirstSet: 22,
            isComplete: true
        )
        context.insert(match1)
        context.insert(match2)
        context.insert(match3)

        // Show results for season #4
        return SeasonalResultsView(seasonNumber: 4)
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
