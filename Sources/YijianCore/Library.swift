import Foundation

public struct GameLibrary {
    public let directory: URL
    public init(directory: URL) { self.directory = directory }
    public static var standard: GameLibrary {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return GameLibrary(directory: root.appendingPathComponent("Yijian/Games", isDirectory: true))
    }
    public func save(_ record: GameRecord) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(record).write(to: directory.appendingPathComponent("\(record.id.uuidString).yijian"), options: .atomic)
    }
    public func list() throws -> [GameRecord] {
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "yijian" }
            .map { try Self.read($0) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    public static func read(_ url: URL) throws -> GameRecord {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard (attributes[.size] as? Int ?? 0) <= 20_000_000 else { throw GameError.invalidData("棋谱文件超过 20 MB，请选择弈间导出的棋谱") }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        var record = try decoder.decode(GameRecord.self, from: Data(contentsOf: url))
        try record.validate()
        return record
    }
    public static func exportNative(_ record: GameRecord, to url: URL) throws {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(record).write(to: url, options: .atomic)
    }
    public static func pgn(_ record: GameRecord) -> String {
        func escape(_ s: String) -> String { s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: " ") }
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy.MM.dd"; formatter.locale = Locale(identifier: "en_US_POSIX")
        let opponent = "\(record.kind.engine) (\(record.difficulty.title))"
        let white = record.humanSide == .white ? "Player" : opponent
        let black = record.humanSide == .black ? "Player" : opponent
        let tags = [("Event", record.name), ("Site", "Yijian / offline"), ("Date", formatter.string(from: record.createdAt)), ("Round", "-"), ("White", white), ("Black", black), ("Result", record.result)]
        var output = tags.map { "[\($0.0) \"\(escape($0.1))\"]" }.joined(separator: "\n") + "\n\n"
        for (i, move) in record.moves.enumerated() { output += (i.isMultiple(of: 2) ? "\(i / 2 + 1). " : "") + move.notation + " " }
        return output + record.result + "\n"
    }
    public static func sgf(_ record: GameRecord) -> String {
        func escape(_ s: String) -> String { s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "]", with: "\\]") }
        let opponent = "GNU Go (\(record.difficulty.title))"
        let black = record.humanSide == .black ? "Player" : opponent
        let white = record.humanSide == .white ? "Player" : opponent
        var output = "(;GM[1]FF[4]CA[UTF-8]AP[Yijian:1.0]SZ[\(record.size)]KM[7.5]RU[Chinese]PB[\(escape(black))]PW[\(escape(white))]GN[\(escape(record.name))]"
        if record.ended { output += "RE[\(record.result)]" }
        for move in record.moves {
            let point = BoardPoint.gtp(move.code, size: record.size)
            let coordinate = point.map { String(UnicodeScalar(97 + $0.x)!) + String(UnicodeScalar(97 + $0.y)!) } ?? ""
            output += ";\(move.side == .black ? "B" : "W")[\(coordinate)]"
        }
        return output + ")\n"
    }
}
