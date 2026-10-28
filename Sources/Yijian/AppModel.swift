import SwiftUI
import AppKit
import UniformTypeIdentifiers
import YijianCore

enum Screen: String, CaseIterable {
    case play = "对弈练习", learn = "入门学堂", library = "我的棋谱", review = "棋局复盘"
    var symbol: String { switch self { case .play: return "square.grid.2x2"; case .learn: return "book.closed"; case .library: return "tray.full"; case .review: return "arrow.counterclockwise.circle" } }
}

@MainActor final class AppModel: ObservableObject {
    @Published var screen: Screen = .play
    @Published var record: GameRecord
    @Published var records: [GameRecord] = []
    @Published var selection: BoardPoint?
    @Published var hint: Analysis?
    @Published var busy = ""
    @Published var error: String?
    @Published var notice = ""
    @Published var promotions: [LegalMove] = []
    @Published var reviewRecord: GameRecord?
    @Published var reviewIndex = 0
    @Published var showNewGame = false
    @Published var showAbout = false
    @Published var showResign = false
    @Published var setupKind: GameKind = .chess
    @Published var setupDifficulty: Difficulty = .easy
    @Published var setupSize = 9
    @Published var setupFirst = true
    @Published var learnKind: GameKind = .chess
    @Published var completed: Set<String>
    let engines = EngineService(directory: EngineService.bundledDirectory)
    let library: GameLibrary
    private var work: Task<Void, Never>?

    init() {
        if let path = ProcessInfo.processInfo.environment["YIJIAN_DATA_DIR"] {
            library = GameLibrary(directory: URL(fileURLWithPath: path))
        } else { library = .standard }
        completed = Set(UserDefaults.standard.stringArray(forKey: "Yijian.CompletedLessons") ?? [])
        record = GameRecord(kind: .chess)
        do {
            records = try library.list()
            if let previous = records.first(where: { !$0.ended }) { record = previous }
        } catch { self.error = "读取棋谱库失败：\(error.localizedDescription)。原文件保留在应用数据目录中。" }
    }
    var isBusy: Bool { !busy.isEmpty }
    var canPlay: Bool { !isBusy && !record.ended && record.current.turn == record.humanSide }
    var canUndo: Bool { !isBusy && record.moves.contains(where: { $0.side == record.humanSide }) }
    var targets: Set<BoardPoint> {
        guard let selection, record.kind != .go else { return [] }
        return Set(record.current.legal.compactMap { move in
            let squares = BoardPoint.uciSquares(move.code, rows: record.rows)
            return squares.count == 2 && squares[0] == selection ? squares[1] : nil
        })
    }
    var status: String {
        if isBusy { return busy }
        if record.ended { return record.resultTitle }
        if record.current.inCheck { return "\(record.current.turn.name(in: record.kind))被将军，请应将" }
        return record.current.turn == record.humanSide ? "轮到你了，慢慢想一想" : "轮到 AI · 点击重试继续"
    }
    func perform(_ message: String, operation: @escaping @MainActor () async throws -> Void) {
        guard !isBusy else { return }
        busy = message; error = nil
        work = Task {
            do { try await operation() }
            catch is CancellationError { }
            catch { self.error = error.localizedDescription }
            busy = ""; work = nil
        }
    }
    func bootstrap() {
        perform("正在准备棋盘…") {
            try await self.restore()
            try await self.computerTurn()
        }
    }
    func restore() async throws {
        let position = try await engines.inspect(kind: record.kind, size: record.size, moves: record.moves.map(\.code))
        if !record.moves.isEmpty && position.pieces != record.current.pieces {
            throw GameError.invalidData("棋谱与引擎重建的局面不一致，无法继续。你仍可以回看棋谱。")
        }
        record.positions[record.positions.count - 1] = position
        if !record.ended { record.result = position.result; record.resultDetail = GameRecord.endReason(position.reason, kind: record.kind) }
    }
    func configure(_ kind: GameKind? = nil) {
        setupKind = kind ?? record.kind; setupDifficulty = record.difficulty; setupSize = record.size; setupFirst = true; showNewGame = true
    }
    func start() {
        guard !isBusy else { return }
        let next = GameRecord(kind: setupKind, size: setupSize, difficulty: setupDifficulty, humanSide: setupFirst ? setupKind.firstSide : setupKind.firstSide.opposite)
        showNewGame = false; screen = .play; selection = nil; hint = nil; notice = ""
        perform("正在准备棋盘…") {
            if !self.record.moves.isEmpty { try self.persist() }
            self.record = next
            try await self.restore()
            try await self.computerTurn()
        }
    }
    func tap(_ point: BoardPoint) {
        guard canPlay else { return }
        if record.kind == .go {
            let code = point.gtp(size: record.size)
            if let move = record.current.legal.first(where: { $0.code == code }) { play(move) }
            else { notice = "这里不能落子：可能已占用、无气或形成重复局面。" }
            return
        }
        let candidates = record.current.legal.filter {
            let squares = BoardPoint.uciSquares($0.code, rows: record.rows)
            return squares.count == 2 && squares[0] == selection && squares[1] == point
        }
        if candidates.count > 1 { promotions = candidates; return }
        if let move = candidates.first { play(move); return }
        let piece = record.current.piece(at: point, columns: record.columns)
        let isWhite = !piece.isEmpty && piece == piece.uppercased()
        if !piece.isEmpty && (isWhite ? Side.white : Side.black) == record.humanSide {
            selection = selection == point ? nil : point; hint = nil; notice = ""
        } else { selection = nil }
    }
    func play(_ move: LegalMove) {
        guard canPlay, record.current.legal.contains(where: { $0.code == move.code }) else { return }
        promotions = []; selection = nil; hint = nil; notice = ""
        perform("正在落子…") {
            try await self.apply(move)
            try await self.computerTurn()
        }
    }
    private func apply(_ move: LegalMove) async throws {
        let position = try await engines.inspect(kind: record.kind, size: record.size, moves: record.moves.map(\.code) + [move.code])
        record.append(move, position: position)
        try persist()
    }
    private func computerTurn() async throws {
        guard !record.ended, record.current.turn != record.humanSide else { return }
        busy = "AI 正在思考…"
        let code = try await engines.bestMove(record: record)
        if code == "resign" {
            finish(winner: record.humanSide, detail: "AI 认输"); try persist(); return
        }
        guard let move = record.current.legal.first(where: { $0.code == code }) else { throw GameError.engine("AI 返回了无效着法，棋局已保留，请重试") }
        try await apply(move)
    }
    func retry() { bootstrap() }
    func undo() {
        guard canUndo else { return }
        perform("正在悔棋…") {
            // Keep the original line in the library; practice continues in a new record.
            try self.persist()
            var index = self.record.moves.count - 1
            while index > 0 && self.record.positions[index].turn != self.record.humanSide { index -= 1 }
            self.record.id = UUID(); self.record.name = "\(self.record.kind.title) · 悔棋练习"
            self.record.moves = Array(self.record.moves.prefix(index))
            self.record.positions = Array(self.record.positions.prefix(index + 1))
            self.record.analyses = self.record.analyses.filter { $0.key <= index }
            self.record.result = "*"; self.record.resultDetail = ""; self.record.updatedAt = Date()
            self.selection = nil; self.hint = nil
            try await self.restore(); try self.persist()
            self.notice = "已回到你上次落子前，原棋谱保留在棋谱库。"
        }
    }
    func requestHint() {
        guard canPlay else { return }
        perform("正在寻找建议着法…") {
            self.hint = try await self.engines.analyse(record: self.record, at: self.record.moves.count)
            if let hint = self.hint, self.record.kind != .go { self.selection = BoardPoint.uciSquares(hint.moveCode, rows: self.record.rows).first }
        }
    }
    func resign() {
        guard !isBusy, !record.ended else { return }
        finish(winner: record.humanSide.opposite, detail: "玩家认输")
        do { try persist() } catch { self.error = error.localizedDescription }
    }
    private func finish(winner: Side, detail: String) {
        record.result = record.kind == .go ? (winner == .black ? "B+R" : "W+R") : (winner == .white ? "1-0" : "0-1")
        record.resultDetail = detail; record.updatedAt = Date(); selection = nil
    }
    func persist() throws {
        try library.save(record)
        records.removeAll { $0.id == record.id }; records.insert(record, at: 0)
    }
    func save() {
        do { try persist(); notice = "棋谱已保存在“我的棋谱”中。" }
        catch { self.error = error.localizedDescription }
    }
    func review(_ game: GameRecord? = nil) {
        guard !isBusy else { return }
        reviewRecord = game ?? record; reviewIndex = (game ?? record).moves.count; screen = .review
    }
    func seek(_ index: Int) {
        guard let game = reviewRecord else { return }
        reviewIndex = max(0, min(index, game.moves.count))
    }
    func analyseReview() {
        guard let game = reviewRecord else { return }
        let index = reviewIndex
        perform("正在分析第 \(index) 手…") {
            let analysis = try await self.engines.analyse(record: game, at: index)
            guard self.reviewRecord?.id == game.id else { return }
            self.reviewRecord?.analyses[index] = analysis
            if var updated = self.reviewRecord {
                updated.updatedAt = Date(); self.reviewRecord = updated
                try self.library.save(updated)
                self.records.removeAll { $0.id == updated.id }; self.records.insert(updated, at: 0)
                if self.record.id == updated.id { self.record.analyses[index] = analysis }
            }
        }
    }
    func resume() {
        guard let game = reviewRecord, !game.ended, !isBusy else { return }
        record = game; selection = nil; hint = nil; screen = .play
        bootstrap()
    }
    func markCompleted(_ id: String) {
        completed.insert(id); UserDefaults.standard.set(Array(completed), forKey: "Yijian.CompletedLessons")
    }
    func importGame() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [UTType(filenameExtension: "yijian") ?? UTType(exportedAs: "com.yijian.game", conformingTo: .json)]; panel.allowsMultipleSelection = false
        panel.message = "选择弈间导出的 .yijian 棋谱，可完整恢复对局与复盘。"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            var game = try GameLibrary.read(url)
            if records.contains(where: { $0.id == game.id }) { game.id = UUID(); game.name += " · 导入" }
            try library.save(game); records.insert(game, at: 0); review(game)
        } catch { self.error = "导入失败：\(error.localizedDescription)" }
    }
    func export(_ game: GameRecord, standard: Bool = false) {
        let ext = standard && game.kind == .chess ? "pgn" : standard && game.kind == .go ? "sgf" : "yijian"
        let panel = NSSavePanel(); panel.allowedContentTypes = [UTType(filenameExtension: ext) ?? .plainText]; panel.nameFieldStringValue = "\(game.name).\(ext)"
        panel.message = ext == "yijian" ? "完整棋谱，可在弈间重新打开和继续练习。" : "导出标准棋谱，供其他棋类软件阅读。"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            if ext == "pgn" { try GameLibrary.pgn(game).write(to: url, atomically: true, encoding: .utf8) }
            else if ext == "sgf" { try GameLibrary.sgf(game).write(to: url, atomically: true, encoding: .utf8) }
            else { try GameLibrary.exportNative(game, to: url) }
            notice = "已导出 \(url.lastPathComponent)"
        } catch { self.error = error.localizedDescription }
    }
}
