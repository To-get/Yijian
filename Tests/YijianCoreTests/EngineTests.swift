import Foundation
import Testing
@testable import YijianCore

struct EngineTests {
    private func service() -> EngineService {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return EngineService(directory: root.appendingPathComponent("Resources/engines"))
    }
    @Test func testChessStartAndSAN() async throws {
        let engine = service()
        let position = try await engine.inspect(kind: .chess)
        #expect((position.legal.count) == (20))
        #expect((position.legal.first { $0.code == "e2e4" }?.notation) == ("e4"))
        #expect((position.pieces.filter { !$0.isEmpty }.count) == (32))
        await engine.shutdown()
    }
    @Test func testCastlingAndPromotion() async throws {
        let engine = service()
        let castle = try await engine.inspect(kind: .chess, fen: "r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
        #expect((castle.legal.first { $0.code == "e1g1" }?.notation) == ("O-O"))
        #expect((castle.legal.first { $0.code == "e1c1" }?.notation) == ("O-O-O"))
        let blocked = try await engine.inspect(kind: .chess, fen: "r3kr1r/8/8/8/8/8/8/R3K2R w KQ - 0 1")
        #expect(!(blocked.legal.contains { $0.code == "e1g1" }))
        let promotion = try await engine.inspect(kind: .chess, fen: "7k/P7/8/8/8/8/8/7K w - - 0 1")
        #expect((Set(promotion.legal.filter { $0.code.hasPrefix("a7a8") }.map(\.code))) == (Set(["a7a8q", "a7a8r", "a7a8b", "a7a8n"])))
        await engine.shutdown()
    }
    @Test func testEnPassantAndExpiry() async throws {
        let engine = service()
        let moves = ["e2e4", "a7a6", "e4e5", "d7d5"]
        let before = try await engine.inspect(kind: .chess, moves: moves)
        #expect(before.legal.contains { $0.code == "e5d6" })
        let after = try await engine.inspect(kind: .chess, moves: moves + ["e5d6"])
        #expect((after.piece(at: BoardPoint(3, 3), columns: 8)) == (""))
        #expect((after.piece(at: BoardPoint(3, 2), columns: 8)) == ("P"))
        let expired = try await engine.inspect(kind: .chess, moves: moves + ["g1f3", "a6a5"])
        #expect(!(expired.legal.contains { $0.code == "e5d6" }))
        await engine.shutdown()
    }
    @Test func testCheckmateStalemateAndMaterialDraw() async throws {
        let engine = service()
        let mate = try await engine.inspect(kind: .chess, moves: ["f2f3", "e7e5", "g2g4", "d8h4"])
        #expect(mate.inCheck); #expect((mate.result) == ("0-1")); #expect((mate.reason) == ("mate")); #expect(mate.legal.isEmpty)
        let stalemate = try await engine.inspect(kind: .chess, fen: "7k/5Q2/6K1/8/8/8/8/8 b - - 0 1")
        #expect((stalemate.result) == ("1/2-1/2")); #expect((stalemate.reason) == ("stalemate"))
        let material = try await engine.inspect(kind: .chess, fen: "7k/8/8/8/8/8/8/K7 w - - 0 1")
        #expect((material.reason) == ("material")); #expect((material.result) == ("1/2-1/2"))
        await engine.shutdown()
    }
    @Test func testRepetitionAndFiftyMoveRule() async throws {
        let engine = service()
        let cycle = ["g1f3", "g8f6", "f3g1", "f6g8"]
        let repeated = try await engine.inspect(kind: .chess, moves: cycle + cycle)
        #expect((repeated.result) == ("1/2-1/2"))
        let fifty = try await engine.inspect(kind: .chess, fen: "7k/8/8/8/8/8/8/R6K w - - 100 60")
        #expect((fifty.result) == ("1/2-1/2"))
        await engine.shutdown()
    }
    @Test func testXiangqiStartCannonAndNotation() async throws {
        let engine = service()
        let position = try await engine.inspect(kind: .xiangqi)
        #expect((position.legal.count) == (44))
        #expect(position.legal.contains { $0.code == "b3b10" })
        #expect(!(position.legal.contains { $0.code == "b3b8" }))
        #expect((position.legal.first { $0.code == "h3e3" }?.notation) == ("炮二平五"))
        #expect((position.pieces.count) == (90))
        await engine.shutdown()
    }
    @Test func testXiangqiHorseElephantFlyingGeneralAndStalemate() async throws {
        let engine = service()
        let horse = try await engine.inspect(kind: .xiangqi, fen: "4k4/9/9/9/4p4/9/9/9/1P7/1N2K4 w - - 0 1")
        #expect(!(horse.legal.contains { $0.code == "b1c3" || $0.code == "b1a3" }))
        let elephant = try await engine.inspect(kind: .xiangqi, fen: "4k4/9/9/9/4p4/9/9/9/3P5/2B1K4 w - - 0 1")
        #expect(!(elephant.legal.contains { $0.code == "c1e3" }))
        #expect(elephant.legal.contains { $0.code == "c1a3" })
        let facing = try await engine.inspect(kind: .xiangqi, fen: "4k4/9/9/9/4P4/9/9/9/9/4K4 w - - 0 1")
        #expect(!(facing.legal.contains { $0.code == "e6d6" || $0.code == "e6f6" }))
        let stalemate = try await engine.inspect(kind: .xiangqi, fen: "3rkr3/9/9/9/9/9/9/4p4/9/4K4 w - - 0 1")
        #expect(!(stalemate.inCheck)); #expect(stalemate.legal.isEmpty); #expect((stalemate.result) == ("0-1"))
        await engine.shutdown()
    }
    @Test func testGoBoardSizesCaptureAndSuicide() async throws {
        let engine = service()
        for size in [9, 13, 19] {
            let position = try await engine.inspect(kind: .go, size: size)
            #expect((position.pieces.count) == (size * size)); #expect((position.legal.count) == (size * size + 1))
        }
        let captured = try await engine.inspect(kind: .go, moves: ["B2", "A2", "J9", "B1", "J8", "C2", "J7", "B3"])
        #expect((captured.piece(at: BoardPoint.gtp("B2", size: 9)!, columns: 9)) == (""))
        #expect((captured.whiteCaptures) == (1))
        #expect(!(captured.legal.contains { $0.code == "B2" }))
        await engine.shutdown()
    }
    @Test func testGoKoAndDoublePass() async throws {
        let engine = service()
        let ko = try await engine.inspect(kind: .go, moves: ["B3", "C3", "D3", "B2", "C4", "D2", "J9", "C1", "C2"])
        #expect(!(ko.legal.contains { $0.code == "C3" }))
        let ended = try await engine.inspect(kind: .go, moves: ["pass", "pass"])
        #expect((ended.result) == ("W+7.5")); #expect((ended.reason) == ("passes"))
        await engine.shutdown()
    }
    @Test func testEveryAIDifficultyReturnsLegalMoveForEveryGame() async throws {
        let engine = service()
        for kind in GameKind.allCases {
            for level in Difficulty.allCases {
                var game = GameRecord(kind: kind, difficulty: level)
                game.positions[0] = try await engine.inspect(kind: kind)
                let move = try await engine.bestMove(record: game)
                #expect(game.current.legal.contains { $0.code == move }, "\(kind) \(level): \(move)")
            }
        }
        await engine.shutdown()
    }
    @Test func testAnalysisAndEngineSwitching() async throws {
        let engine = service()
        for kind in GameKind.allCases {
            var game = GameRecord(kind: kind)
            game.positions[0] = try await engine.inspect(kind: kind)
            let move = game.current.legal.first!
            game.append(move, position: try await engine.inspect(kind: kind, moves: [move.code]))
            let analysis = try await engine.analyse(record: game, at: 1)
            #expect(analysis.value.isFinite)
            #expect(game.current.legal.contains { $0.code == analysis.moveCode })
        }
        let chess = try await engine.inspect(kind: .chess)
        #expect((chess.legal.count) == (20))
        await engine.shutdown()
    }
}
