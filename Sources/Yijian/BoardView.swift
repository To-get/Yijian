import SwiftUI
import YijianCore

struct BoardView: View {
    let kind: GameKind
    let size: Int
    let position: Position
    var lastMove: String?
    var selection: BoardPoint?
    var targets: Set<BoardPoint> = []
    var hintCode: String?
    var flipped = false
    var interactive = true
    var onTap: (BoardPoint) -> Void = { _ in }
    private var columns: Int { kind.columns(size: size) }
    private var rows: Int { kind.rows(size: size) }
    private var lastSquares: [BoardPoint] {
        guard let lastMove else { return [] }
        return kind == .go ? BoardPoint.gtp(lastMove, size: size).map { [$0] } ?? [] : BoardPoint.uciSquares(lastMove, rows: rows)
    }
    private var suggested: BoardPoint? {
        guard let hintCode else { return nil }
        return kind == .go ? BoardPoint.gtp(hintCode, size: size) : BoardPoint.uciSquares(hintCode, rows: rows).last
    }
    var body: some View {
        GeometryReader { geometry in
            let padding: CGFloat = 27
            let step = min((geometry.size.width - padding * 2) / CGFloat(kind == .chess ? columns : columns - 1), (geometry.size.height - padding * 2) / CGFloat(kind == .chess ? rows : rows - 1))
            let width = step * CGFloat(kind == .chess ? columns : columns - 1) + padding * 2
            let height = step * CGFloat(kind == .chess ? rows : rows - 1) + padding * 2
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12).fill(kind == .chess ? Color(hex: 0xE6E9DE) : Theme.wood)
                Canvas { context, _ in
                    drawLines(context: context, step: step, padding: padding)
                    for x in 0..<columns {
                        let file = flipped ? columns - 1 - x : x
                        let label = kind == .go ? String(Array("ABCDEFGHJKLMNOPQRST")[file]) : String(UnicodeScalar(97 + file)!)
                        let xPos = padding + step * (CGFloat(x) + (kind == .chess ? 0.5 : 0))
                        context.draw(Text(label).font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundColor(Theme.muted), at: CGPoint(x: xPos, y: height - 10))
                    }
                    for y in 0..<rows {
                        let rank = flipped ? y + 1 : rows - y
                        let yPos = padding + step * (CGFloat(y) + (kind == .chess ? 0.5 : 0))
                        context.draw(Text(String(rank)).font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundColor(Theme.muted), at: CGPoint(x: 11, y: yPos))
                    }
                }
                ForEach(0..<(rows * columns), id: \.self) { index in
                    let visualX = index % columns, visualY = index / columns
                    let point = BoardPoint(flipped ? columns - 1 - visualX : visualX, flipped ? rows - 1 - visualY : visualY)
                    let piece = position.piece(at: point, columns: columns)
                    BoardCell(kind: kind, piece: piece, step: step, selected: selection == point, legal: targets.contains(point), last: lastSquares.contains(point), latest: lastSquares.last == point, suggested: suggested == point, label: squareLabel(point, piece: piece), interactive: interactive) { onTap(point) }
                        .frame(width: step, height: step)
                        .position(x: padding + step * (CGFloat(visualX) + (kind == .chess ? 0.5 : 0)), y: padding + step * (CGFloat(visualY) + (kind == .chess ? 0.5 : 0)))
                }
            }
            .frame(width: width, height: height)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink.opacity(0.12), lineWidth: 1))
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .accessibilityElement(children: .contain).accessibilityLabel("\(kind.title)棋盘")
    }
    private func squareLabel(_ point: BoardPoint, piece: String) -> String {
        let coordinate = kind == .go ? point.gtp(size: size) : point.uci(rows: rows)
        let name = piece.isEmpty ? "空位" : kind == .go ? (piece == "b" ? "黑子" : "白子") : "\(piece == piece.uppercased() ? Side.white.name(in: kind) : Side.black.name(in: kind))\(PieceView.name(piece, kind: kind))"
        return "\(coordinate) \(name)\(targets.contains(point) ? " 可落子" : "")\(selection == point ? " 已选中" : "")"
    }
    private func drawLines(context: GraphicsContext, step: CGFloat, padding: CGFloat) {
        if kind == .chess {
            for y in 0..<rows { for x in 0..<columns {
                let rect = CGRect(x: padding + CGFloat(x) * step, y: padding + CGFloat(y) * step, width: step, height: step)
                context.fill(Path(rect), with: .color((x + y).isMultiple(of: 2) ? Color(hex: 0xF5F0DF) : Color(hex: 0x79917B)))
            } }
            return
        }
        var path = Path()
        for y in 0..<rows {
            path.move(to: CGPoint(x: padding, y: padding + CGFloat(y) * step)); path.addLine(to: CGPoint(x: padding + CGFloat(columns - 1) * step, y: padding + CGFloat(y) * step))
        }
        for x in 0..<columns {
            let px = padding + CGFloat(x) * step
            path.move(to: CGPoint(x: px, y: padding))
            if kind == .xiangqi && x > 0 && x < columns - 1 {
                path.addLine(to: CGPoint(x: px, y: padding + step * 4)); path.move(to: CGPoint(x: px, y: padding + step * 5))
            }
            path.addLine(to: CGPoint(x: px, y: padding + CGFloat(rows - 1) * step))
        }
        if kind == .xiangqi {
            for y in [0, 7] {
                path.move(to: CGPoint(x: padding + step * 3, y: padding + step * CGFloat(y)))
                path.addLine(to: CGPoint(x: padding + step * 5, y: padding + step * CGFloat(y + 2)))
                path.move(to: CGPoint(x: padding + step * 5, y: padding + step * CGFloat(y)))
                path.addLine(to: CGPoint(x: padding + step * 3, y: padding + step * CGFloat(y + 2)))
            }
            for (x, label) in [(2.0, "楚 河"), (6.0, "汉 界")] {
                context.draw(Text(label).font(.system(size: min(22, step * 0.42), weight: .medium, design: .serif)).foregroundColor(Color(hex: 0x806445)), at: CGPoint(x: padding + step * x, y: padding + step * 4.5))
            }
        }
        context.stroke(path, with: .color(Color(hex: 0x957F5E)), lineWidth: 0.8)
        if kind == .go {
            let points = size == 9 ? [BoardPoint(2,2), BoardPoint(6,2), BoardPoint(4,4), BoardPoint(2,6), BoardPoint(6,6)] : [3, size/2, size-4].flatMap { x in [3, size/2, size-4].map { BoardPoint(x, $0) } }
            for point in points {
                context.fill(Path(ellipseIn: CGRect(x: padding + CGFloat(point.x) * step - 2.5, y: padding + CGFloat(point.y) * step - 2.5, width: 5, height: 5)), with: .color(Color(hex: 0x78664D)))
            }
        }
    }
}

private struct BoardCell: View {
    let kind: GameKind
    let piece: String
    let step: CGFloat
    let selected: Bool
    let legal: Bool
    let last: Bool
    let latest: Bool
    let suggested: Bool
    let label: String
    let interactive: Bool
    let action: () -> Void
    @ViewState private var hovering = false
    var body: some View {
        Button(action: action) {
            ZStack {
                if kind == .chess {
                    Rectangle().fill(selected ? Theme.gold.opacity(0.7) : last ? Color(hex: 0xD9BC62).opacity(0.45) : Color.clear)
                    if hovering && interactive { Rectangle().fill(Color.white.opacity(0.18)) }
                }
                if !piece.isEmpty { PieceView(kind: kind, piece: piece, size: step * (kind == .chess ? 0.86 : 0.82)) }
                if legal { Circle().fill(Theme.ink.opacity(piece.isEmpty ? 0.38 : 0.15)).frame(width: piece.isEmpty ? step * 0.22 : step * 0.82).overlay(Circle().stroke(piece.isEmpty ? Color.clear : Theme.ink, lineWidth: 2)) }
                if (selected && kind != .chess) || suggested { RoundedRectangle(cornerRadius: kind == .chess ? 4 : step / 2).stroke(Theme.accent, lineWidth: 3).padding(2) }
                if latest && kind != .chess { Circle().fill(kind == .go && piece == "b" ? Color.white : Theme.accent).frame(width: max(5, step * 0.12), height: max(5, step * 0.12)).offset(y: kind == .xiangqi ? step * 0.31 : 0) }
            }.frame(width: step, height: step).contentShape(Rectangle())
        }
        .buttonStyle(.plain).disabled(!interactive).onHover { hovering = $0 }
        .accessibilityLabel(label).help(label)
    }
}

struct PieceView: View {
    let kind: GameKind
    let piece: String
    let size: CGFloat
    private var white: Bool { piece == piece.uppercased() }
    static func name(_ piece: String, kind: GameKind) -> String {
        if kind == .chess { return ["p":"兵", "n":"马", "b":"象", "r":"车", "q":"后", "k":"王"][piece.lowercased()] ?? piece }
        let red = piece == piece.uppercased()
        return ["p":red ? "兵" : "卒", "n":"马", "h":"马", "b":red ? "相" : "象", "e":red ? "相" : "象", "r":"车", "a":red ? "仕" : "士", "k":red ? "帅" : "将", "c":"炮"][piece.lowercased()] ?? piece
    }
    var body: some View {
        if kind == .go {
            Circle().fill(piece == "b" ? Color(hex: 0x26332E) : Color(hex: 0xFCFBF3)).overlay(Circle().stroke(Color.black.opacity(0.14), lineWidth: 1)).shadow(color: .black.opacity(0.2), radius: 1.5, x: 0, y: 2).frame(width: size, height: size)
        } else if kind == .xiangqi {
            Text(Self.name(piece, kind: kind)).font(.system(size: size * 0.59, weight: .semibold, design: .serif))
                .foregroundStyle(white ? Color(hex: 0xAB3D2E) : Theme.ink)
                .frame(width: size, height: size).background(Color(hex: 0xFBEDCF), in: Circle())
                .overlay(Circle().stroke(white ? Color(hex: 0xAF5D45) : Color(hex: 0x526554), lineWidth: 1.3).padding(3))
                .overlay(Circle().stroke(Color(hex: 0xAD8D61), lineWidth: 1)).shadow(color: .black.opacity(0.14), radius: 1, x: 0, y: 2)
        } else {
            let glyph = ["p":"♟", "n":"♞", "b":"♝", "r":"♜", "q":"♛", "k":"♚"][piece.lowercased()] ?? piece
            Text(glyph).font(.system(size: size * 0.85)).foregroundStyle(white ? Color(hex: 0xFFFEF6) : Color(hex: 0x20382E))
                .shadow(color: white ? Color(hex: 0x3E5345) : Color.clear, radius: 0.5, x: 0.8, y: 0.8)
                .shadow(color: white ? Color(hex: 0x3E5345) : Color.clear, radius: 0.5, x: -0.8, y: -0.8)
                .frame(width: size, height: size)
        }
    }
}
