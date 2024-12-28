import Foundation
import SwiftData

@Model
class Season {
    @Attribute(.unique) var seasonNumber: Int
    var isCompleted: Bool
    @Relationship(inverse: \Session.season) var sessions: [Session] = []

    init(seasonNumber: Int, isCompleted: Bool = false) {
        self.seasonNumber = seasonNumber
        self.isCompleted = isCompleted
    }
}
