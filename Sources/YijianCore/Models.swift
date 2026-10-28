import Foundation

public enum GameKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case chess, xiangqi, go
    public var id: String { rawValue }
    public var title: String { switch self { case .chess: return "国际象棋"; case .xiangqi: return "中国象棋"; case .go: return "围棋" } }
    public var english: String { switch self { case .chess: return "CHESS"; case .xiangqi: return "XIANGQI"; case .go: return "GO" } }
    public var subtitle: String { switch self { case .chess: return "方寸之间，运筹帷幄"; case .xiangqi: return "楚河汉界，落子生趣"; case .go: return "黑白相间，见天地宽" } }
    public var firstSide: Side { self == .go ? .black : .white }
    public var engine: String { self == .go ? "GNU Go 3.8" : "Fairy-Stockfish" }
    public func columns(size: Int) -> Int { self == .go ? size : self == .chess ? 8 : 9 }
    public func rows(size: Int) -> Int { self == .go ? size : self == .chess ? 8 : 10 }
}

public enum Side: String, Codable, Sendable {
    case white, black
    public var opposite: Side { self == .white ? .black : .white }
    public func name(in kind: GameKind) -> String { kind == .xiangqi ? (self == .white ? "红方" : "黑方") : (self == .white ? "白方" : "黑方") }
    public var gtp: String { rawValue }
}

public enum Difficulty: Int, Codable, CaseIterable, Identifiable, Sendable {
    case gentle, easy, medium, hard
    public var id: Int { rawValue }
    public var title: String { ["启蒙", "入门", "进阶", "挑战"][rawValue] }
    public var detail: String { ["熟悉规则，轻松落子", "练习布局，发现机会", "认真计算，稳步提高", "更深搜索，检验棋力"][rawValue] }
    public var skill: Int { [-20, -5, 6, 20][rawValue] }
    public var milliseconds: Int { [180, 350, 700, 1500][rawValue] }
    public var goLevel: Int { [0, 2, 5, 10][rawValue] }
}

public struct BoardPoint: Hashable, Codable, Sendable {
    public let x: Int
    public let y: Int
    public init(_ x: Int, _ y: Int) { self.x = x; self.y = y }
    public func uci(rows: Int) -> String { "\(String(UnicodeScalar(97 + x)!))\(rows - y)" }
    public func gtp(size: Int) -> String { "\(Array("ABCDEFGHJKLMNOPQRST")[x])\(size - y)" }
    public static func gtp(_ value: String, size: Int) -> BoardPoint? {
        let chars = Array(value.uppercased())
        guard let first = chars.first, let x = Array("ABCDEFGHJKLMNOPQRST").firstIndex(of: first),
              let rank = Int(String(chars.dropFirst())), x < size, (1...size).contains(rank) else { return nil }
        return BoardPoint(x, size - rank)
    }
    public static func uciSquares(_ move: String, rows: Int) -> [BoardPoint] {
        let regex = try! NSRegularExpression(pattern: "[a-i](?:10|[1-9])")
        return regex.matches(in: move, range: NSRange(move.startIndex..., in: move)).compactMap {
            guard let range = Range($0.range, in: move) else { return nil }
            let s = String(move[range]); let chars = Array(s)
            guard let scalar = chars[0].asciiValue, let rank = Int(s.dropFirst()), rank <= rows else { return nil }
            return BoardPoint(Int(scalar) - 97, rows - rank)
        }
    }
}

public struct LegalMove: Codable, Equatable, Sendable {
    public let code: String
    public let notation: String
    public init(code: String, notation: String) { self.code = code; self.notation = notation }
}

public struct Position: Codable, Equatable, Sendable {
    public var pieces: [String]
    public var turn: Side
    public var legal: [LegalMove]
    public var fen: String
    public var inCheck: Bool
    public var result: String
    public var reason: String
    public var blackCaptures: Int
    public var whiteCaptures: Int
    public init(pieces: [String], turn: Side, legal: [LegalMove] = [], fen: String = "", inCheck: Bool = false, result: String = "*", reason: String = "ongoing", blackCaptures: Int = 0, whiteCaptures: Int = 0) {
        self.pieces = pieces; self.turn = turn; self.legal = legal; self.fen = fen
        self.inCheck = inCheck; self.result = result; self.reason = reason
        self.blackCaptures = blackCaptures; self.whiteCaptures = whiteCaptures
    }
    public func piece(at point: BoardPoint, columns: Int) -> String {
        let index = point.y * columns + point.x
        guard point.x >= 0, point.x < columns, point.y >= 0, pieces.indices.contains(index) else { return "" }
        return pieces[index]
    }
    public static func fromFEN(_ fen: String, kind: GameKind) throws -> Position {
        let fields = fen.split(separator: " ")
        let rows = kind.rows(size: 9), columns = kind.columns(size: 9)
        guard fields.count >= 2, fields[1] == "w" || fields[1] == "b" else { throw GameError.invalidData("局面格式不正确") }
        let ranks = fields[0].split(separator: "/")
        guard ranks.count == rows else { throw GameError.invalidData("棋盘行数不正确") }
        var pieces: [String] = []
        for rank in ranks {
            var row: [String] = []
            for char in rank {
                if let n = char.wholeNumberValue, n > 0 { row += Array(repeating: "", count: n) }
                else if "prnbqkacPRNBQKACheHE".contains(char) { row.append(String(char)) }
                else { throw GameError.invalidData("不支持的棋子") }
            }
            guard row.count == columns else { throw GameError.invalidData("棋盘列数不正确") }
            pieces += row
        }
        return Position(pieces: pieces, turn: fields[1] == "w" ? .white : .black, fen: fen)
    }
    public static func initial(kind: GameKind, size: Int) -> Position {
        switch kind {
        case .chess: return try! fromFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", kind: kind)
        case .xiangqi: return try! fromFEN("rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1", kind: kind)
        case .go: return Position(pieces: Array(repeating: "", count: size * size), turn: .black)
        }
    }
}

public struct PlayedMove: Codable, Equatable, Sendable {
    public let code: String
    public let notation: String
    public let side: Side
    public init(code: String, notation: String, side: Side) { self.code = code; self.notation = notation; self.side = side }
}

public struct Analysis: Codable, Equatable, Sendable {
    // Positive favors the first player: white/red in chess, black in Go.
    public let value: Double
    public let mate: Int?
    public let suggestion: String
    public let moveCode: String
    public let detail: String
    public init(value: Double, mate: Int? = nil, suggestion: String, moveCode: String, detail: String) {
        self.value = value; self.mate = mate; self.suggestion = suggestion; self.moveCode = moveCode; self.detail = detail
    }
}

public struct GameRecord: Codable, Identifiable, Sendable {
    public var version = 1
    public var id: UUID
    public var name: String
    public var kind: GameKind
    public var size: Int
    public var difficulty: Difficulty
    public var humanSide: Side
    public var createdAt: Date
    public var updatedAt: Date
    public var positions: [Position]
    public var moves: [PlayedMove]
    public var result: String
    public var resultDetail: String
    public var analyses: [Int: Analysis]
    public init(kind: GameKind, size: Int = 9, difficulty: Difficulty = .easy, humanSide: Side? = nil) {
        id = UUID(); name = "\(kind.title) · \(difficulty.title)练习"; self.kind = kind; self.size = size
        self.difficulty = difficulty; self.humanSide = humanSide ?? kind.firstSide
        createdAt = Date(); updatedAt = Date(); positions = [.initial(kind: kind, size: size)]
        moves = []; result = "*"; resultDetail = ""; analyses = [:]
    }
    public var current: Position { positions.last! }
    public var ended: Bool { result != "*" }
    public var columns: Int { kind.columns(size: size) }
    public var rows: Int { kind.rows(size: size) }
    public mutating func append(_ move: LegalMove, position: Position) {
        moves.append(PlayedMove(code: move.code, notation: move.notation, side: current.turn))
        positions.append(position); result = position.result; updatedAt = Date()
        if ended { resultDetail = Self.endReason(position.reason, kind: kind) }
    }
    public static func endReason(_ reason: String, kind: GameKind) -> String {
        switch reason {
        case "mate": return kind == .xiangqi ? "将死" : "将杀"
        case "stalemate": return kind == .xiangqi ? "困毙" : "逼和"
        case "material": return "子力不足，和棋"
        case "rule": return "重复局面或步数规则裁定"
        case "passes": return "双方停一手，按中国规则自动数子（含死活估计）"
        case "resign": return "认输"
        default: return "规则裁定"
        }
    }
    public var resultTitle: String {
        if result == "*" { return "进行中" }
        if result == "1/2-1/2" || result == "0" { return "和棋" }
        let winner: Side = kind == .go ? (result.hasPrefix("B") ? .black : .white) : (result == "1-0" ? .white : .black)
        if kind == .go, Double(result.dropFirst(2)) != nil { return "\(winner.name(in: kind))胜 \(result.dropFirst(2)) 目" }
        return "\(winner.name(in: kind))获胜"
    }
    public mutating func validate() throws {
        guard version == 1, [9,13,19].contains(size), !positions.isEmpty, moves.count <= 10000,
              positions.count == moves.count + 1, name.count <= 200 else { throw GameError.invalidData("棋谱版本或结构不正确") }
        let validPieces = kind == .go ? ["", "b", "w"] : [""] + Array("prnbqkacPRNBQKACheHE").map(String.init)
        for position in positions {
            guard position.pieces.count == rows * columns, position.pieces.allSatisfy({ validPieces.contains($0) }),
                  position.legal.count <= 400 else { throw GameError.invalidData("棋谱中的棋盘数据不正确") }
        }
        let pattern = kind == .go ? "^(?:[A-HJ-T](?:[1-9]|1[0-9])|pass)$" : "^[a-i](?:10|[1-9])[a-i](?:10|[1-9])[qrbn]?$"
        for move in moves {
            guard move.code.range(of: pattern, options: .regularExpression) != nil, move.notation.count <= 100 else { throw GameError.invalidData("棋谱包含无效着法") }
        }
        guard analyses.keys.allSatisfy({ positions.indices.contains($0) }), analyses.values.allSatisfy({ $0.value.isFinite }) else { throw GameError.invalidData("复盘数据不正确") }
    }
}

public enum GameError: LocalizedError {
    case invalidData(String), engine(String), timeout, missingEngine
    public var errorDescription: String? {
        switch self {
        case .invalidData(let message), .engine(let message): return message
        case .timeout: return "引擎思考超时。当前棋谱已保留，请点击重试。"
        case .missingEngine: return "找不到内置引擎，请使用完整的弈间应用，或先运行构建脚本。"
        }
    }
}

public func xiangqiNotation(_ raw: String, side: Side) -> String {
    let pieces: [Character: String] = ["K": side == .white ? "帅" : "将", "A": side == .white ? "仕" : "士", "B": side == .white ? "相" : "象", "E": side == .white ? "相" : "象", "N": "马", "H": "马", "R": "车", "C": "炮", "P": side == .white ? "兵" : "卒"]
    let chars = Array(raw)
    guard chars.count >= 4, let name = pieces[chars[0]] else { return raw }
    func numeral(_ c: Character) -> String {
        if side == .white, let n = c.wholeNumberValue, n > 0, n <= 9 { return String(Array("一二三四五六七八九")[n - 1]) }
        return String(c)
    }
    let origin = chars[1] == "+" ? "前" : chars[1] == "-" ? "后" : numeral(chars[1])
    let prefix = ["+", "-"].contains(chars[1]) ? origin + name : name + origin
    let action = chars[2] == "+" ? "进" : chars[2] == "-" ? "退" : chars[2] == "=" ? "平" : String(chars[2])
    return prefix + action + numeral(chars[3]) + String(chars.dropFirst(4))
}
