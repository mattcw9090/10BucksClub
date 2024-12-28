import SwiftUI

enum DetailSegment: String, CaseIterable, Identifiable {
    case teams = "Teams"
    case draws = "Draws"
    case results = "Results"
    case seasonalResults = "Season"
    
    var id: String { self.rawValue }
}

struct SessionDetailView: View {
    let seasonNumber: Int
    let sessionNumber: Int
    
    @State private var selectedSegment: DetailSegment = .teams
    
    var body: some View {
        VStack {
            Picker("View", selection: $selectedSegment) {
                ForEach(DetailSegment.allCases) { segment in
                    Text(segment.rawValue)
                        .tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top)
            
            switch selectedSegment {
            case .teams:
                TeamsView(seasonNumber: seasonNumber, sessionNumber: sessionNumber)
            case .draws:
                DrawsView(seasonNumber: seasonNumber, sessionNumber: sessionNumber)
            case .results:
                ResultsView(seasonNumber: seasonNumber, sessionNumber: sessionNumber)
            case .seasonalResults:
                SeasonalResultsView(seasonNumber: seasonNumber)
            }
            
            Spacer()
        }
        .navigationTitle("Season \(seasonNumber) Session \(sessionNumber)")
    }
}

#Preview {
    SessionDetailView(seasonNumber: 2, sessionNumber: 3)
}
