import SwiftUI

struct DrawsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                WaveView(
                    title: "Wave 1",
                    matches: [
                        Match(name1: "Shin", name2: "Suan Sian Foo", name3: "Chris Fan", name4: "CJ", isCompleted: true, winningTeam: .Red, score: "21-15"),
                        Match(name1: "Nicson Hiew", name2: "Issac Lai", name3: "Krishna H", name4: "Jarred N", isCompleted: false, winningTeam: nil, score: nil)
                    ]
                )
                
                WaveView(
                    title: "Wave 2",
                    matches: [
                        Match(name1: "Suan Sian Foo", name2: "Kevin Shen", name3: "CJ", name4: "Moritz", isCompleted: true, winningTeam: .Black, score: "18-21"),
                        Match(name1: "Nicson Hiew", name2: "Li Han", name3: "Krishna H", name4: "Steven M", isCompleted: false, winningTeam: nil, score: nil)
                    ]
                )
            }
        }
        .padding(.horizontal)
    }
}

struct WaveView: View {
    let title: String
    let matches: [Match]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 5)

            VStack(spacing: 0) {
                ForEach(matches, id: \.id) { match in
                    MatchView(
                        name1: match.name1,
                        name2: match.name2,
                        name3: match.name3,
                        name4: match.name4,
                        isCompleted: match.isCompleted,
                        winningTeam: match.winningTeam,
                        score: match.score
                    )
                }
            }
        }
    }
}

struct Match: Identifiable {
    let id = UUID()
    let name1: String
    let name2: String
    let name3: String
    let name4: String
    let isCompleted: Bool
    let winningTeam: Team?
    let score: String?
}

struct MatchView: View {
    let name1: String
    let name2: String
    let name3: String
    let name4: String
    let isCompleted: Bool
    let winningTeam: Team?
    let score: String?

    @State private var showScore: Bool = false
    @State private var inputScore: String = ""

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text(name1)
                    Text(name2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

                Text("vs")
                    .bold()

                VStack(alignment: .trailing, spacing: 10) {
                    Text(name3)
                    Text(name4)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
            }
            .background(isCompleted ? winningTeamColor : Color.clear)
            .border(Color.gray, width: 1)
            .padding(.horizontal)
            .onTapGesture {
                if isCompleted {
                    withAnimation {
                        showScore.toggle()
                    }
                } else {
                    withAnimation {
                        showScore.toggle()
                    }
                }
            }

            if showScore {
                if isCompleted, let matchScore = score {
                    Text("Score: \(matchScore)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.top, 5)
                } else {
                    VStack {
                        TextField("Enter score", text: $inputScore)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)

                        Button("Save") {
                            print("Score saved: \(inputScore)")
                            showScore = false
                        }
                        .padding(.top, 5)
                    }
                }
            }
        }
    }

    private var winningTeamColor: Color {
        switch winningTeam {
        case .Red: return Color.red.opacity(0.2)
        case .Black: return Color.black.opacity(0.2)
        default: return Color.green.opacity(0.2)
        }
    }
}

#Preview {
    DrawsView()
}
