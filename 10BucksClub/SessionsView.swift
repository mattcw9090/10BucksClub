import SwiftUI
import SwiftData

struct SessionsView: View {
    @Query(sort: \Season.seasonNumber, order: .forward)
    private var seasons: [Season]
    
    @Query(sort: \Session.sessionNumber, order: .forward)
    private var allSessions: [Session]
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var expandedSeasons: [Int: Bool] = [:]
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(seasons) { season in
                        let isExpanded = Binding(
                            get: { expandedSeasons[season.seasonNumber] ?? false },
                            set: { expandedSeasons[season.seasonNumber] = $0 }
                        )
                        
                        let sessionsForSeason = allSessions.filter { $0.season.id == season.id }
                        
                        SeasonAccordionView(
                            isExpanded: isExpanded,
                            seasonNumber: season.seasonNumber,
                            sessions: sessionsForSeason,
                            isCompleted: season.isCompleted
                        )
                    }
                }
                .listStyle(InsetGroupedListStyle())
                
                VStack(spacing: 10) {
                    Button(action: addNewSeason) {
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
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Cannot Add Season"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // MARK: - Actions
    
    private func addNewSeason() {
        // Check if all seasons are completed
        guard seasons.allSatisfy({ $0.isCompleted }) else {
            alertMessage = "All previous seasons must be marked as completed before adding a new season."
            showAlert = true
            return
        }
        
        // Determine the next season number
        let nextSeasonNumber = (seasons.map { $0.seasonNumber }.max() ?? 0) + 1
        
        // Create a new season
        let newSeason = Season(seasonNumber: nextSeasonNumber)
        
        // Insert the new season into the model context
        modelContext.insert(newSeason)
        
        do {
            // Save the context to persist the data
            try modelContext.save()
            print("New season added: Season \(nextSeasonNumber)")
        } catch {
            alertMessage = "Failed to save the new season: \(error)"
            showAlert = true
        }
    }
}


struct SeasonAccordionView: View {
    @Binding var isExpanded: Bool
    let seasonNumber: Int
    let sessions: [Session]
    let isCompleted: Bool
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                if !sessions.isEmpty {
                    ForEach(sessions) { session in
                        NavigationLink(destination: SessionDetailView(seasonNumber: seasonNumber, sessionNumber: session.sessionNumber)) {
                            HStack {
                                Image(systemName: "calendar.circle.fill")
                                Text("Session \(session.sessionNumber)")
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
                            addSession(seasonNumber: seasonNumber)
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
                            markSeasonComplete(seasonNumber: seasonNumber)
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
    
    // MARK: - Actions
    
    private func addSession(seasonNumber: Int) {
        // Implement your add session logic here
        // Example:
        // Find the Season object by seasonNumber
        // let newSession = Session(sessionNumber: nextSessionNumber, season: foundSeason)
        // context.insert(newSession)
        // try? context.save()
    }
    
    private func markSeasonComplete(seasonNumber: Int) {
        // Implement your mark season complete logic here
        // Example:
        // Find the Season object by seasonNumber
        // foundSeason.isCompleted = true
        // try? context.save()
    }
}

#Preview {
    let schema = Schema([Season.self, Session.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    
    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        // Insert Mock Data
        let context = mockContainer.mainContext
        
        let season1 = Season(seasonNumber: 1)
        let season2 = Season(seasonNumber: 2, isCompleted: true)
        context.insert(season1)
        context.insert(season2)
        let session1 = Session(sessionNumber: 1, season: season1)
        let session2 = Session(sessionNumber: 2, season: season1)
        context.insert(session1)
        context.insert(session2)
        let session3 = Session(sessionNumber: 1, season: season2)
        context.insert(session3)
        
        return SessionsView()
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
