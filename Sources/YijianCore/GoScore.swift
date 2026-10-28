import Foundation

public enum GoScore {
    // Count the position actually accepted by both players. GNU Go supplies
    // dead-stone judgments; its final_score instead simulates further play.
    public static func areaResult(position: Position, size: Int, dead: Set<BoardPoint>, komi: Double = 7.5) -> String {
        var board = position.pieces
        for point in dead where point.x >= 0 && point.x < size && point.y >= 0 && point.y < size {
            board[point.y * size + point.x] = ""
        }
        var black = board.filter { $0 == "b" }.count
        var white = board.filter { $0 == "w" }.count
        var visited: Set<Int> = []
        for start in board.indices where board[start].isEmpty && !visited.contains(start) {
            var queue = [start]; var borders: Set<String> = []; var cursor = 0
            visited.insert(start)
            while cursor < queue.count {
                let index = queue[cursor]; cursor += 1
                let x = index % size, y = index / size
                for (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)] where nx >= 0 && nx < size && ny >= 0 && ny < size {
                    let neighbor = ny * size + nx
                    if board[neighbor].isEmpty {
                        if visited.insert(neighbor).inserted { queue.append(neighbor) }
                    } else { borders.insert(board[neighbor]) }
                }
            }
            if borders == ["b"] { black += queue.count }
            if borders == ["w"] { white += queue.count }
        }
        let difference = Double(black - white) - komi
        if difference == 0 { return "0" }
        return "\(difference > 0 ? "B" : "W")+\(String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), abs(difference)))"
    }
}
