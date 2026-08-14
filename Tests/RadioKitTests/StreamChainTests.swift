import Foundation
import Testing

@testable import RadioKit

struct StreamChainTests {
  @Test func ordersCandidatesByAvailabilityRankAndInputOrder() throws {
    let firstEqualRank = RadioStreamCandidate(
      url: try #require(URL(string: "https://example.com/first")),
      rank: 1
    )
    let secondEqualRank = RadioStreamCandidate(
      url: try #require(URL(string: "https://example.com/second")),
      rank: 1
    )
    let lowerRank = RadioStreamCandidate(
      url: try #require(URL(string: "https://example.com/lower-rank")),
      rank: 0
    )
    let offline = RadioStreamCandidate(
      url: try #require(URL(string: "https://example.com/offline")),
      rank: -1,
      isOffline: true
    )

    var chain = StreamChain([offline, firstEqualRank, secondEqualRank, lowerRank])
    var ordered = [RadioStreamCandidate]()
    while let candidate = chain.current {
      ordered.append(candidate)
      chain.advance()
    }

    #expect(ordered == [lowerRank, firstEqualRank, secondEqualRank, offline])
  }

  @Test func advancesCountsAttemptsAndResetsAfterExhaustion() throws {
    let first = RadioStreamCandidate(
      url: try #require(URL(string: "https://example.com/first"))
    )
    let second = RadioStreamCandidate(
      url: try #require(URL(string: "https://example.com/second")),
      rank: 1
    )
    var chain = StreamChain([first, second])

    #expect(chain.current == first)
    #expect(chain.triedCount == 1)
    #expect(chain.advance() == second)
    #expect(chain.triedCount == 2)
    #expect(chain.advance() == nil)
    #expect(chain.isExhausted)
    #expect(chain.triedCount == 2)

    chain.reset()
    #expect(chain.current == first)
    #expect(chain.triedCount == 1)
  }
}
