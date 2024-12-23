import SwiftUI

struct TeamsView: View {
    var body: some View {
        NavigationView {
            List {
                // Red Team Section
                Section(header: HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                    Text("Red Team")
                        .font(.headline)
                        .foregroundColor(.red)
                }) {
                    ForEach(redTeam, id: \.self) { member in
                        TeamMemberRow(name: member, team: .Red)
                    }
                }

                // Black Team Section
                Section(header: HStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 10, height: 10)
                    Text("Black Team")
                        .font(.headline)
                        .foregroundColor(.black)
                }) {
                    ForEach(blackTeam, id: \.self) { member in
                        TeamMemberRow(name: member, team: .Black)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
}

// MARK: - Supporting Views and Data

let redTeam = [
    "Shin Hean",
    "Suan Sian Foo",
    "Kevin Shen",
    "Nicson Hiew",
    "Issac Lai",
    "Li Han"
]

let blackTeam = [
    "Chris Fan",
    "CJ",
    "Moritz",
    "Krishna Hareesh",
    "Jarred Norman",
    "Steven Manoharan"
]

struct TeamMemberRow: View {
    let name: String
    let team: Team

    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundColor(teamColor)
                .frame(width: 30, height: 30)
            Text(name)
                .font(.body)
                .padding(.leading, 5)
        }
        .padding(.vertical, 5)
    }

    private var teamColor: Color {
        switch team {
        case .Red:
            return .red
        case .Black:
            return .black
        }
    }
}

#Preview {
    TeamsView()
}
