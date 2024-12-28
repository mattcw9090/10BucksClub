import SwiftUI
import SwiftData

struct SessionsView: View {
    @Query(sort: \Season.seasonNumber, order: .forward)
    private var seasons: [Season]
    
    @State private var isSeasonExpanded: Bool = false
    @State private var expandedSeasons: [Int: Bool] = [:]

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(seasons) { season in
                        let isExpanded = Binding(
                            get: { expandedSeasons[season.seasonNumber] ?? false },
                            set: { expandedSeasons[season.seasonNumber] = $0 }
                        )
                        
                        SeasonAccordionView(
                            isExpanded: isExpanded,
                            seasonNumber: season.seasonNumber,
                            sessionCount: season.sessions.count,
                            isCompleted: season.isCompleted
                        )
                    }
                }
                .listStyle(InsetGroupedListStyle())

                VStack(spacing: 10) {
                    Button(action: {
                    }) {
                        Text("Add New Season")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Sessions")
        }
    }
}

struct SeasonAccordionView: View {
    @Binding var isExpanded: Bool
    let seasonNumber: Int
    let sessionCount: Int
    let isCompleted: Bool

    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                if sessionCount > 0 {
                    ForEach(1...sessionCount, id: \ .self) { sessionNumber in
                        NavigationLink(destination: SessionDetailView(seasonNumber: seasonNumber, sessionNumber: sessionNumber)) {
                            HStack {
                                Image(systemName: "calendar.circle.fill")
                                Text("Session \(sessionNumber)")
                                    .font(.body)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                } else {
                    Text("No sessions")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 5)
                }

                if !isCompleted {
                    HStack(spacing: 10) {
                        Button(action: {
                            // Add session action
                        }) {
                            Text("Add Session")
                                .padding(.vertical, 5)
                                .padding(.horizontal, 10)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                                .font(.caption)
                        }

                        Button(action: {
                            // Mark complete action
                        }) {
                            Text("Mark Complete")
                                .padding(.vertical, 5)
                                .padding(.horizontal, 10)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                                .font(.caption)
                        }
                    }
                    .padding(.top, 10)
                }
            },
            label: {
                HStack {
                    Text("Season \(seasonNumber)")
                        .font(.headline)
                        .foregroundColor(isCompleted ? .black : .blue)
                    Spacer()
                    Text(isCompleted ? "Completed" : "In Progress")
                        .font(.subheadline)
                        .foregroundColor(isCompleted ? .black : .blue)
                }
            }
        )
    }
}

#Preview {
    let schema = Schema([Session.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])

        // Insert Mock Data
        let context = mockContainer.mainContext
        context.insert(Season(seasonNumber: 10))
        let season4 = Season(seasonNumber: 4)
        context.insert(season4)
        context.insert(Session(number: 1, season: season4))
        context.insert(Session(number: 2, season: season4))

        return SessionsView()
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
