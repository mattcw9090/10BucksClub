import Foundation

struct MatchPair: Hashable {
    let a: Int
    let b: Int
    
    init(_ x: Int, _ y: Int) {
        // Always store lower value in `a` for consistent hashing
        if x < y {
            a = x
            b = y
        } else {
            a = y
            b = x
        }
    }
}

func allCombinations(of array: [Int]) -> Set<MatchPair> {
    var result = Set<MatchPair>()
    for i in 0..<array.count {
        for j in i+1..<array.count {
            result.insert(MatchPair(array[i], array[j]))
        }
    }
    return result
}

func groupMatches(_ tuples: Set<MatchPair>, _ k: Int) -> [[MatchPair]]? {
    let allTuples = Array(tuples)
    let n = allTuples.count
    let numSets = n / k

    // Preliminary frequency check
    var freq = [Int: Int]()
    for pair in allTuples {
        freq[pair.a, default: 0] += 1
        freq[pair.b, default: 0] += 1
    }
    for (player, count) in freq {
        if count > 2 * numSets {
            print("No solution possible because number '\(player)' appears too many times (\(count) times).")
            return nil
        }
    }

    var setsList: [[MatchPair]] = Array(repeating: [], count: numSets)
    var usedInSet: [Set<Int>] = Array(repeating: Set<Int>(), count: numSets)
    var usedTuple: [Bool] = Array(repeating: false, count: n)

    var consecutiveCount = [Int: Int]()
    var lastSetOf = [Int: Int]()

    func canPlaceTupleInSet(_ pair: MatchPair, in s: Int) -> Bool {
        let (a, b) = (pair.a, pair.b)
        
        // Already used in set s?
        if usedInSet[s].contains(a) || usedInSet[s].contains(b) {
            return false
        }
        
        // Check consecutive limit (<= 2)
        let oldAConsecutive = consecutiveCount[a, default: 0]
        let oldALast = lastSetOf[a, default: -1]
        let aConsecutiveIfPlaced: Int
        if oldALast == s - 1 {
            aConsecutiveIfPlaced = oldAConsecutive + 1
        } else {
            aConsecutiveIfPlaced = 1
        }
        if aConsecutiveIfPlaced > 2 {
            return false
        }

        let oldBConsecutive = consecutiveCount[b, default: 0]
        let oldBLast = lastSetOf[b, default: -1]
        let bConsecutiveIfPlaced: Int
        if oldBLast == s - 1 {
            bConsecutiveIfPlaced = oldBConsecutive + 1
        } else {
            bConsecutiveIfPlaced = 1
        }
        if bConsecutiveIfPlaced > 2 {
            return false
        }

        return true
    }

    func placeTupleInSet(_ pair: MatchPair, in s: Int) {
        setsList[s].append(pair)
        usedInSet[s].insert(pair.a)
        usedInSet[s].insert(pair.b)
    }

    func removeTupleFromSet(_ pair: MatchPair, in s: Int) {
        if let idx = setsList[s].firstIndex(of: pair) {
            setsList[s].remove(at: idx)
        }
        usedInSet[s].remove(pair.a)
        usedInSet[s].remove(pair.b)
    }

    func updateConsecutiveCountsOnPlace(_ pair: MatchPair, in s: Int) -> (Int, Int, Int, Int) {
        let (a, b) = (pair.a, pair.b)
        
        let oldAConsecutive = consecutiveCount[a, default: 0]
        let oldALast = lastSetOf[a, default: -1]
        if oldALast == s - 1 {
            consecutiveCount[a] = oldAConsecutive + 1
        } else {
            consecutiveCount[a] = 1
        }
        lastSetOf[a] = s

        let oldBConsecutive = consecutiveCount[b, default: 0]
        let oldBLast = lastSetOf[b, default: -1]
        if oldBLast == s - 1 {
            consecutiveCount[b] = oldBConsecutive + 1
        } else {
            consecutiveCount[b] = 1
        }
        lastSetOf[b] = s

        return (oldAConsecutive, oldBConsecutive, oldALast, oldBLast)
    }

    func rollbackConsecutiveCounts(_ pair: MatchPair, oldVals: (Int, Int, Int, Int)) {
        let (a, b) = (pair.a, pair.b)
        let (oldAConsecutive, oldBConsecutive, oldALast, oldBLast) = oldVals

        if oldALast == -1 && oldAConsecutive == 0 {
            consecutiveCount.removeValue(forKey: a)
            lastSetOf.removeValue(forKey: a)
        } else {
            consecutiveCount[a] = oldAConsecutive
            lastSetOf[a] = oldALast
        }

        if oldBLast == -1 && oldBConsecutive == 0 {
            consecutiveCount.removeValue(forKey: b)
            lastSetOf.removeValue(forKey: b)
        } else {
            consecutiveCount[b] = oldBConsecutive
            lastSetOf[b] = oldBLast
        }
    }

    func fillSet(_ s: Int, startIdx: Int) -> Bool {
        if s == numSets {
            return true
        }
        if setsList[s].count == k {
            return fillSet(s + 1, startIdx: 0)
        }
        for i in startIdx..<n {
            if usedTuple[i] { continue }
            let pair = allTuples[i]
            if canPlaceTupleInSet(pair, in: s) {
                placeTupleInSet(pair, in: s)
                usedTuple[i] = true
                let oldVals = updateConsecutiveCountsOnPlace(pair, in: s)
                
                if fillSet(s, startIdx: i + 1) {
                    return true
                }
                
                // Backtrack
                rollbackConsecutiveCounts(pair, oldVals: oldVals)
                removeTupleFromSet(pair, in: s)
                usedTuple[i] = false
            }
        }
        return false
    }

    let success = fillSet(0, startIdx: 0)
    if !success {
        return nil
    }
    return setsList
}


class Logic {
    /// Attempts a single run with given parameters and returns a tuple:
    /// - success: bool
    /// - lineup: optional array of waves
    /// - matchCount: dictionary of usage
    ///
    /// Parameters:
    /// - teamMembers: Array of team member IDs.
    /// - numberOfWaves: Number of waves.
    /// - numberOfCourts: Number of courts per wave.
    func runOnce(teamMembers: [Int], numberOfWaves: Int, numberOfCourts: Int) -> (success: Bool, lineup: [[MatchPair]]?, matchCount: [Int: Int]) {
        let numberOfMatches = numberOfWaves * numberOfCourts

        // All possible pairs
        var allCombos = allCombinations(of: teamMembers)

        // If not enough combos, fail immediately
        if allCombos.count < numberOfMatches {
            return (false, nil, [:])
        }

        // matchCount
        var matchCount = [Int: Int]()
        for player in teamMembers {
            matchCount[player] = 0
        }

        var selectedMatches = Set<MatchPair>()
        
        // Keep picking until we reach numberOfMatches
        while selectedMatches.count < numberOfMatches {
            let minCount = matchCount.values.min() ?? 0
            let maxCount = matchCount.values.max() ?? 0

            let maxPlayers = matchCount.filter { $0.value == maxCount }.map { $0.key }
            let minPlayers = matchCount.filter { $0.value == minCount }.map { $0.key }

            let actualPool: Set<MatchPair>
            if minCount == maxCount {
                actualPool = allCombos
            } else if maxCount - minCount == 1 {
                // remove pairs that have any in maxPlayers
                var temp = allCombos.filter {
                    !maxPlayers.contains($0.a) && !maxPlayers.contains($0.b)
                }
                if temp.isEmpty {
                    // fallback: keep only pairs that have at least one in minPlayers
                    temp = allCombos.filter {
                        minPlayers.contains($0.a) || minPlayers.contains($0.b)
                    }
                }
                actualPool = Set(temp)
            } else {
                // remove pairs that have any in maxPlayers
                var temp = allCombos.filter {
                    !maxPlayers.contains($0.a) && !maxPlayers.contains($0.b)
                }
                // keep only pairs that have at least one in minPlayers
                temp = temp.filter {
                    minPlayers.contains($0.a) || minPlayers.contains($0.b)
                }
                actualPool = Set(temp)
            }

            guard let picked = actualPool.randomElement() else {
                // no possible picks
                return (false, nil, matchCount)
            }

            allCombos.remove(picked)
            selectedMatches.insert(picked)

            matchCount[picked.a, default: 0] += 1
            matchCount[picked.b, default: 0] += 1
        }

        // Now order them
        if let lineup = groupMatches(selectedMatches, numberOfCourts) {
            return (true, lineup, matchCount)
        } else {
            return (false, nil, matchCount)
        }
    }

    /// Tries up to `maxTries` to get a valid lineup.
    /// If it succeeds, it prints the results and stops.
    /// If it fails all attempts, it prints "No valid lineup found."
    func runExampleWithRetries(teamMembers: [Int], numberOfWaves: Int, numberOfCourts: Int, maxTries: Int = 10) {
        for _ in 1...maxTries {
            let result = runOnce(teamMembers: teamMembers, numberOfWaves: numberOfWaves, numberOfCourts: numberOfCourts)
            if result.success {
                // Print the success results
                if let lineup = result.lineup {
                    for (idx, wave) in lineup.enumerated() {
                        let waveStr = wave.map { "(\($0.a), \($0.b))" }.joined(separator: ", ")
                        print("Wave \(idx + 1): [\(waveStr)]")
                    }
                    print("\nMatch Count")
                    print(result.matchCount)
                }
                return // stop after first success
            }
        }
        // If we are here, all attempts failed
        print("No valid lineup found after \(maxTries) attempts.")
    }
}
