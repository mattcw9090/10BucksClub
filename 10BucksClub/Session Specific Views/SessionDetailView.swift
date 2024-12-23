import SwiftUI

enum DetailSegment: String, CaseIterable, Identifiable {
    case teams = "Teams"
    case draws = "Draws"
    case results = "Results"
    case seasonalResults = "Season"
    
    var id: String { self.rawValue }
}

struct SessionDetailView: View {
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
                TeamsView()
            case .draws:
                DrawsView()
            case .results:
                ResultsView()
            case .seasonalResults:
                SeasonalResultsView()
            }
            
            Spacer()
        }
        .navigationTitle("Session \(sessionNumber)")
    }
}

#Preview {
    SessionDetailView(sessionNumber: 3)
}
