import Foundation
import Testing
@testable import YijianCore

struct LibraryTests {
    @Test func testChineseAreaCountsTheAcceptedBoard() {
        var position = Position(pieces: Array(repeating: "", count: 9), turn: .black)
        #expect(GoScore.areaResult(position: position, size: 3, dead: []) == "W+7.5")
        position.pieces[0] = "b"
        #expect(GoScore.areaResult(position: position, size: 3, dead: []) == "B+1.5")
        position.pieces[8] = "w"
        #expect(GoScore.areaResult(position: position, size: 3, dead: []) == "W+7.5")
        #expect(GoScore.areaResult(position: position, size: 3, dead: [BoardPoint(2, 2)]) == "B+1.5")
        position.pieces = ["b", "b", "w", "b", "", "w", "b", "w", "w"]
        #expect(GoScore.areaResult(position: position, size: 3, dead: [], komi: 0) == "0")
    }
    @Test func testAtomicSaveReloadAndExport() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("yijian-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let library = GameLibrary(directory: root)
        var record = GameRecord(kind: .chess, difficulty: .hard, humanSide: .black)
        record.positions[0].legal = [LegalMove(code: "e2e4", notation: "e4")]
        let after = try Position.fromFEN("rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1", kind: .chess)
        record.append(record.current.legal[0], position: after)
        record.analyses[1] = Analysis(value: 0.2, suggestion: "e5", moveCode: "e7e5", detail: "test")
        try library.save(record)
        try library.save(record)
        let saved = try library.list()
        #expect((saved.count) == (1)); #expect((saved[0].id) == (record.id))
        #expect((saved[0].positions) == (record.positions)); #expect((saved[0].moves) == (record.moves))
        #expect((saved[0].analyses) == (record.analyses)); #expect((saved[0].humanSide) == (.black))
        let exported = root.appendingPathComponent("copy.yijian")
        try GameLibrary.exportNative(record, to: exported)
        let imported = try GameLibrary.read(exported)
        #expect((imported.moves[0].notation) == ("e4"))
        #expect(GameLibrary.pgn(imported).contains("1. e4 *"))
    }
    @Test func testSGFCoordinatesPassAndEscaping() throws {
        var record = GameRecord(kind: .go)
        record.name = "test]name\\"
        record.append(LegalMove(code: "A9", notation: "A9"), position: Position(pieces: Array(repeating: "", count: 81), turn: .white))
        record.append(LegalMove(code: "pass", notation: "停一手"), position: Position(pieces: Array(repeating: "", count: 81), turn: .black))
        let sgf = GameLibrary.sgf(record)
        #expect(sgf.contains(";B[aa];W[]")); #expect(sgf.contains("GN[test\\]name\\\\]")); #expect(sgf.contains("KM[7.5]"))
        #expect((BoardPoint.gtp("J1", size: 9)) == (BoardPoint(8, 8)))
        #expect(BoardPoint.gtp("I3", size: 9) == nil)
    }
    @Test func testMalformedRecordsAreRejected() throws {
        var game = GameRecord(kind: .chess)
        game.positions = []
        #expect(throws: (any Error).self) { try game.validate() }
        game = GameRecord(kind: .go); game.size = 0
        #expect(throws: (any Error).self) { try game.validate() }
        game = GameRecord(kind: .chess)
        game.append(LegalMove(code: "e2e4\nquit", notation: "e4"), position: game.current)
        #expect(throws: (any Error).self) { try game.validate() }
        game = GameRecord(kind: .chess); game.positions[0].pieces = ["x"]
        #expect(throws: (any Error).self) { try game.validate() }
    }
    @Test func testCoordinatesAndXiangqiText() {
        #expect((BoardPoint.uciSquares("b3b10", rows: 10)) == ([BoardPoint(1, 7), BoardPoint(1, 0)]))
        #expect((BoardPoint.uciSquares("a7a8q", rows: 8)) == ([BoardPoint(0, 1), BoardPoint(0, 0)]))
        #expect((xiangqiNotation("H2+3", side: .white)) == ("马二进三"))
        #expect((xiangqiNotation("C8=5", side: .black)) == ("炮8平5"))
    }
    @Test func testEveryLessonHasValidQuiz() {
        var identifiers: Set<String> = []
        for kind in GameKind.allCases {
            #expect((Lessons.forGame(kind).count) == (3))
            for lesson in Lessons.forGame(kind) {
                #expect(identifiers.insert(lesson.id).inserted)
                #expect(!(lesson.steps.isEmpty))
                for step in lesson.steps {
                    #expect(step.answers.indices.contains(step.correct)); #expect(!(step.body.isEmpty)); #expect(!(step.explanation.isEmpty))
                }
            }
        }
    }
}
