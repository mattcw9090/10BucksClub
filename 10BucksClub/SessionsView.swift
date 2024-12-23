import SwiftUI

struct SessionsView: View {
    @State private var isSeason1Expanded: Bool = false
    @State private var isSeason2Expanded: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                List {
                    SeasonAccordionView(
                        isExpanded: $isSeason2Expanded,
                        seasonNumber: 2,
                        sessionCount: 5,
                        isFinished: false
                    )

                    SeasonAccordionView(
                        isExpanded: $isSeason1Expanded,
                        seasonNumber: 1,
                        sessionCount: 10,
                        isFinished: true
                    )
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
    let isFinished: Bool

    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                ForEach(1...sessionCount, id: \ .self) { sessionNumber in
                    NavigationLink(destination: SessionDetailView(sessionNumber: sessionNumber)) {
                        HStack {
                            Image(systemName: "calendar.circle.fill")
                            Text("Session \(sessionNumber)")
                                .font(.body)
                        }
                        .padding(.vertical, 5)
                    }
                }

                if !isFinished {
                    HStack(spacing: 10) {
                        Button(action: {
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
                        .foregroundColor(isFinished ? .black : .blue)
                    Spacer()
                    Text(isFinished ? "Completed" : "In Progress")
                        .font(.subheadline)
                        .foregroundColor(isFinished ? .black : .blue)
                }
            }
        )
    }
}

#Preview {
    SessionsView()
}
