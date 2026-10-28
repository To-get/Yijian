import Foundation
import Darwin

// All I/O runs on EngineService's serial actor, never on the UI thread.
// A monotonic deadline and EOF checks bound every engine request.
private final class EnginePipe {
    let process = Process()
    private let input = Pipe()
    private let output = Pipe()
    private var buffer = Data()
    init(url: URL, arguments: [String] = []) throws {
        guard FileManager.default.isExecutableFile(atPath: url.path) else { throw GameError.missingEngine }
        process.executableURL = url; process.arguments = arguments
        process.standardInput = input; process.standardOutput = output; process.standardError = FileHandle.nullDevice
        try process.run()
        let fd = output.fileHandleForReading.fileDescriptor
        _ = fcntl(fd, F_SETFL, fcntl(fd, F_GETFL) | O_NONBLOCK)
    }
    deinit { close() }
    func close() {
        if process.isRunning {
            try? input.fileHandleForWriting.write(contentsOf: Data("quit\n".utf8))
            process.terminate()
        }
        try? input.fileHandleForWriting.close()
        try? output.fileHandleForReading.close()
    }
    func send(_ command: String) throws {
        guard process.isRunning else { throw GameError.engine("引擎已退出，请重试") }
        try input.fileHandleForWriting.write(contentsOf: Data((command + "\n").utf8))
    }
    func lines(timeout: Double = 15, until: (String) -> Bool) throws -> [String] {
        let deadline = ProcessInfo.processInfo.systemUptime + timeout
        var result: [String] = []
        while ProcessInfo.processInfo.systemUptime < deadline {
            try Task.checkCancellation()
            if let end = buffer.firstIndex(of: 10) {
                let line = String(decoding: buffer[..<end], as: UTF8.self).trimmingCharacters(in: .newlines)
                buffer.removeSubrange(...end)
                result.append(line)
                if until(line) { return result }
                continue
            }
            var descriptor = pollfd(fd: output.fileHandleForReading.fileDescriptor, events: Int16(POLLIN | POLLHUP), revents: 0)
            let status = poll(&descriptor, 1, 100)
            if status > 0 {
                var bytes = [UInt8](repeating: 0, count: 8192)
                let count = read(descriptor.fd, &bytes, bytes.count)
                if count > 0 { buffer.append(contentsOf: bytes.prefix(count)) }
                else if count == 0 { throw GameError.engine("引擎意外退出，请重试") }
            } else if status < 0 && errno != EINTR { throw GameError.engine("无法读取引擎响应") }
        }
        throw GameError.timeout
    }
    func gtp(_ command: String, timeout: Double = 40) throws -> String {
        try send(command)
        let response = try lines(timeout: timeout, until: { $0.isEmpty }).filter { !$0.isEmpty }.joined(separator: "\n")
        guard response.hasPrefix("=") else { throw GameError.engine("围棋引擎：\(response.dropFirst().trimmingCharacters(in: .whitespaces))") }
        return String(response.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public actor EngineService {
    private let directory: URL
    private var fairy: EnginePipe?
    private var go: EnginePipe?
    public init(directory: URL) { self.directory = directory }
    public static var bundledDirectory: URL {
        let bundled = Bundle.main.resourceURL?.appendingPathComponent("engines")
        if let bundled, FileManager.default.fileExists(atPath: bundled.appendingPathComponent("fairy-stockfish").path) { return bundled }
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources/engines")
    }
    public func shutdown() { fairy = nil; go = nil }
    private func fairyEngine() throws -> EnginePipe {
        if let fairy { return fairy }
        let engine = try EnginePipe(url: directory.appendingPathComponent("fairy-stockfish"), arguments: ["noautoload"])
        try engine.send("uci")
        _ = try engine.lines(until: { $0 == "uciok" })
        try engine.send("setoption name Threads value 1")
        try engine.send("setoption name Hash value 32")
        try engine.send("setoption name Use NNUE value false")
        fairy = engine
        return engine
    }
    private func goEngine() throws -> EnginePipe {
        if let go { return go }
        let engine = try EnginePipe(url: directory.appendingPathComponent("gnugo"), arguments: ["--mode", "gtp", "--chinese-rules", "--positional-superko", "--quiet"])
        _ = try engine.gtp("protocol_version")
        go = engine
        return engine
    }
    private func setupFairy(kind: GameKind, moves: [String], fen: String? = nil) throws -> EnginePipe {
        let engine = try fairyEngine()
        try engine.send("setoption name UCI_Variant value \(kind.rawValue)")
        let start = fen.map { "fen \($0)" } ?? "startpos"
        try engine.send("position \(start)\(moves.isEmpty ? "" : " moves " + moves.joined(separator: " "))")
        return engine
    }
    private func setupGo(size: Int, moves: [String], level: Int = 5) throws -> EnginePipe {
        let engine = try goEngine()
        _ = try engine.gtp("boardsize \(size)")
        _ = try engine.gtp("clear_board")
        _ = try engine.gtp("komi 7.5")
        _ = try engine.gtp("level \(level)")
        for (index, move) in moves.enumerated() {
            _ = try engine.gtp("play \(index.isMultiple(of: 2) ? "black" : "white") \(move)")
        }
        return engine
    }
    public func inspect(kind: GameKind, size: Int = 9, moves: [String] = [], fen: String? = nil) throws -> Position {
        do {
            if kind == .go {
                let engine = try setupGo(size: size, moves: moves)
                var position = Position(pieces: Array(repeating: "", count: size * size), turn: moves.count.isMultiple(of: 2) ? .black : .white)
                for side in [Side.black, .white] {
                    let stones = try engine.gtp("list_stones \(side.gtp)").split(whereSeparator: { $0.isWhitespace })
                    for stone in stones {
                        guard let point = BoardPoint.gtp(String(stone), size: size) else { throw GameError.engine("围棋引擎返回了无效坐标") }
                        position.pieces[point.y * size + point.x] = side == .black ? "b" : "w"
                    }
                }
                position.blackCaptures = Int(try engine.gtp("captures black")) ?? 0
                position.whiteCaptures = Int(try engine.gtp("captures white")) ?? 0
                let legal = try engine.gtp("all_legal \(position.turn.gtp)").split(whereSeparator: { $0.isWhitespace })
                position.legal = legal.map { LegalMove(code: String($0).uppercased(), notation: String($0).uppercased()) }
                position.legal.append(LegalMove(code: "pass", notation: "停一手"))
                if moves.count >= 2 && moves.suffix(2).allSatisfy({ $0 == "pass" }) {
                    let deadStones = try engine.gtp("final_status_list dead", timeout: 60).split(whereSeparator: { $0.isWhitespace })
                    let dead = Set(deadStones.compactMap { BoardPoint.gtp(String($0), size: size) })
                    position.result = GoScore.areaResult(position: position, size: size, dead: dead)
                    position.reason = "passes"
                }
                return position
            }
            let engine = try setupFairy(kind: kind, moves: moves, fen: fen)
            try engine.send("yijian")
            let lines = try engine.lines(until: { $0 == "yijianok" })
            guard let fenLine = lines.first(where: { $0.hasPrefix("fen ") }) else { throw GameError.engine("无法读取棋盘局面") }
            var position = try Position.fromFEN(String(fenLine.dropFirst(4)), kind: kind)
            position.inCheck = lines.contains("check 1")
            position.result = String(lines.first(where: { $0.hasPrefix("result ") })?.dropFirst(7) ?? "*")
            position.reason = String(lines.first(where: { $0.hasPrefix("reason ") })?.dropFirst(7) ?? "ongoing")
            position.legal = lines.filter { $0.hasPrefix("move ") }.compactMap {
                let parts = $0.dropFirst(5).split(separator: "|", maxSplits: 1)
                guard parts.count == 2 else { return nil }
                let notation = kind == .xiangqi ? xiangqiNotation(String(parts[1]), side: position.turn) : String(parts[1])
                return LegalMove(code: String(parts[0]), notation: notation)
            }
            return position
        } catch { shutdown(); throw error }
    }
    public func bestMove(record: GameRecord) throws -> String {
        do {
            let codes = record.moves.map(\.code)
            if record.kind == .go {
                let engine = try setupGo(size: record.size, moves: codes, level: record.difficulty.goLevel)
                let move = try engine.gtp("reg_genmove \(record.current.turn.gtp)", timeout: 60)
                return ["pass", "resign"].contains(move.lowercased()) ? move.lowercased() : move.uppercased()
            }
            let engine = try setupFairy(kind: record.kind, moves: codes)
            try engine.send("setoption name Skill Level value \(record.difficulty.skill)")
            try engine.send("go movetime \(record.difficulty.milliseconds)")
            let lines = try engine.lines(until: { $0.hasPrefix("bestmove ") })
            guard let line = lines.last, let move = line.split(separator: " ").dropFirst().first else { throw GameError.engine("引擎没有返回着法") }
            return String(move)
        } catch { shutdown(); throw error }
    }
    public func analyse(record: GameRecord, at index: Int) throws -> Analysis {
        do {
            guard record.positions.indices.contains(index) else { throw GameError.invalidData("复盘位置越界") }
            let position = record.positions[index]
            let codes = record.moves.prefix(index).map(\.code)
            if record.kind == .go {
                let engine = try setupGo(size: record.size, moves: codes, level: 8)
                let estimate = try engine.gtp("estimate_score")
                let scoreToken = String(estimate.split(separator: " ").first ?? "W+0")
                let magnitude = Double(scoreToken.dropFirst(2)) ?? 0
                let move = position.result == "*" ? try engine.gtp("reg_genmove \(position.turn.gtp)", timeout: 60) : "pass"
                let code = ["pass", "resign"].contains(move.lowercased()) ? move.lowercased() : move.uppercased()
                return Analysis(value: (scoreToken.hasPrefix("B") ? 1 : -1) * magnitude, suggestion: code == "pass" ? "停一手" : code == "resign" ? "引擎建议认输" : code, moveCode: code, detail: "GNU Go 形势估计，含贴目 7.5。复杂死活可能影响估计，不代表胜率。")
            }
            let engine = try setupFairy(kind: record.kind, moves: codes)
            try engine.send("setoption name Skill Level value 20")
            try engine.send("go movetime 1000")
            let lines = try engine.lines(until: { $0.hasPrefix("bestmove ") })
            let best = String(lines.last?.split(separator: " ").dropFirst().first ?? "(none)")
            let info = lines.last(where: { $0.contains(" score ") && !$0.contains("bound") }) ?? ""
            let parts = info.split(separator: " ").map(String.init)
            var value = 0.0; var mate: Int?
            if let i = parts.firstIndex(of: "score"), i + 2 < parts.count, let score = Double(parts[i + 2]) {
                if parts[i + 1] == "mate" { mate = Int(score); value = score >= 0 ? 100 : -100 }
                else { value = score / 100 }
            }
            let sign = position.turn == .white ? 1.0 : -1.0
            let suggestion = position.legal.first(where: { $0.code == best })?.notation ?? "无可行着法"
            return Analysis(value: value * sign, mate: mate.map { $0 * Int(sign) }, suggestion: suggestion, moveCode: best, detail: "Fairy-Stockfish · 1 秒搜索。正值有利于\(record.kind.firstSide.name(in: record.kind))；评估单位为兵值，不是胜率。")
        } catch { shutdown(); throw error }
    }
}
