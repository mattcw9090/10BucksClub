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
                            isCompleted: season.isCompleted,
                            addSession: { addSession(to: season) },
                            markComplete: { markSeasonComplete(season) }
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
        guard seasons.allSatisfy({ $0.isCompleted }) else {
            alertMessage = "All previous seasons must be marked as completed before adding a new season."
            showAlert = true
            return
        }
        
        let nextSeasonNumber = (seasons.map { $0.seasonNumber }.max() ?? 0) + 1
        let newSeason = Season(seasonNumber: nextSeasonNumber)
        modelContext.insert(newSeason)
        
        do {
            try modelContext.save()
            print("New season added: Season \(nextSeasonNumber)")
        } catch {
            alertMessage = "Failed to save the new season: \(error)"
            showAlert = true
        }
    }
    
    private func addSession(to season: Season) {
        let nextSessionNumber = (allSessions
                                    .filter { $0.season.id == season.id }
                                    .map { $0.sessionNumber }
                                    .max() ?? 0) + 1
        let newSession = Session(sessionNumber: nextSessionNumber, season: season)
        modelContext.insert(newSession)
        
        do {
            try modelContext.save()
            print("New session added: Session \(nextSessionNumber) for Season \(season.seasonNumber)")
        } catch {
            alertMessage = "Failed to save the new session: \(error)"
            showAlert = true
        }
    }
    
    private func markSeasonComplete(_ season: Season) {
        guard let index = seasons.firstIndex(where: { $0.id == season.id }) else { return }
        let updatedSeason = seasons[index]
        updatedSeason.isCompleted = true
        
        do {
            modelContext.insert(updatedSeason)
            try modelContext.save()
            print("Season \(season.seasonNumber) marked as complete")
        } catch {
            alertMessage = "Failed to mark the season as complete: \(error)"
            showAlert = true
        }
    }
}

struct SeasonAccordionView: View {
    @Binding var isExpanded: Bool
    let seasonNumber: Int
    let sessions: [Session]
    let isCompleted: Bool
    let addSession: () -> Void
    let markComplete: () -> Void
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                if !sessions.isEmpty {
                    ForEach(sessions) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
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
                    HStack(spacing: 20) {
                        Button(action: addSession) {
                            Text("Add Session")
                                .padding(.vertical, 5)
                                .padding(.horizontal, 10)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                                .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: markComplete) {
                            Text("Mark Complete")
                                .padding(.vertical, 5)
                                .padding(.horizontal, 10)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                                .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
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
        .contentShape(Rectangle())
    }
}

#Preview {
    let schema = Schema([Season.self, Session.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    
    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        // Insert Mock Data
        let context = mockContainer.mainContext
        
        let season1 = Season(seasonNumber: 1, isCompleted: true)
        context.insert(season1)
        let session1 = Session(sessionNumber: 1, season: season1)
        context.insert(session1)
        
        return SessionsView()
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
