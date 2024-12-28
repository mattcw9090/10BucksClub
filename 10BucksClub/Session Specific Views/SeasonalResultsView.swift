import SwiftUI

struct SeasonalResultsView: View {
    let seasonNumber: Int
    
    var body: some View {
        NavigationView {
            List {
                // Header Row
                SeasonalResultsRowView(playerName: "Player", matches: "Matches", averageScore: "Avg Score", isHeader: true)

                // Player Rows
                SeasonalResultsRowView(playerName: "Alice Johnson", matches: "20", averageScore: "85.4")
                SeasonalResultsRowView(playerName: "Bob Smith", matches: "18", averageScore: "90.2")
                SeasonalResultsRowView(playerName: "Charlie Davis", matches: "22", averageScore: "78.9")
                SeasonalResultsRowView(playerName: "Diana Prince", matches: "19", averageScore: "88.5")
                SeasonalResultsRowView(playerName: "Ethan Hunt", matches: "21", averageScore: "92.3")
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Seasonal Results")
        }
    }
}

struct SeasonalResultsRowView: View {
    var playerName: String
    var matches: String
    var averageScore: String
    var isHeader: Bool = false
    
    var body: some View {
        HStack {
            Text(playerName)
                .font(isHeader ? .headline : .body)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(matches)
                .font(isHeader ? .headline : .body)
                .frame(width: 80, alignment: .trailing)
            Text(averageScore)
                .font(isHeader ? .headline : .body)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.vertical, isHeader ? 10 : 5)
    }
}

#Preview {
    SeasonalResultsView(seasonNumber: 5)
}
