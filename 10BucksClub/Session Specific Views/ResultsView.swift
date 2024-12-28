import SwiftUI

struct ResultsView: View {
    let seasonNumber: Int
    let sessionNumber: Int
    
    var body: some View {
        VStack(spacing: 20) {
            VStack {
                Text("Team Scores")
                    .font(.headline)
                    .padding(.vertical)
                
                HStack {
                    VStack {
                        Text("Red Team")
                            .font(.subheadline)
                        Text("45")
                            .font(.title)
                            .foregroundColor(.red)
                    }
                    Spacer()
                    VStack {
                        Text("Black Team")
                            .font(.subheadline)
                        Text("30")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                }
                .padding()
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()
            
            VStack(alignment: .leading) {
                Text("Player's Score for the Session")
                    .font(.headline)
                    .padding(.bottom, 10)
                
                List {
                    SessionResultsRowView(playerName: "Alice", playerScore: 20)
                    SessionResultsRowView(playerName: "Bob", playerScore: 15)
                    SessionResultsRowView(playerName: "Charlie", playerScore: 10)
                    SessionResultsRowView(playerName: "Diana", playerScore: 5)
                }
            }
            .padding()
        }
    }
}

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

#Preview {
    ResultsView(seasonNumber: 5, sessionNumber: 3)
}
