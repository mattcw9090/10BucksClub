import Foundation
import SwiftData

@Model
class Season {
    @Attribute(.unique)
    var seasonNumber: Int
    
    var isCompleted: Bool
    
    init(seasonNumber: Int, isCompleted: Bool = false) {
        self.seasonNumber = seasonNumber
        self.isCompleted = isCompleted
    }
}
