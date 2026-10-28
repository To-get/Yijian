import SwiftUI
import YijianCore

struct ReviewView: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        if let game = model.reviewRecord {
            content(game)
        } else {
            VStack(spacing: 18) {
                Image(systemName: "arrow.counterclockwise.circle").font(.system(size: 48, weight: .ultraLight))
                Text("重新看见每一次选择").font(.system(size: 26, weight: .medium, design: .serif))
                Button("复盘当前棋局") { model.review() }.buttonStyle(SoftButton(prominent: true))
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    private func content(_ game: GameRecord) -> some View {
        let index = min(model.reviewIndex, game.moves.count)
        return VStack(alignment: .leading, spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 8) { Eyebrow(text: "REFLECT / UNDERSTAND / IMPROVE"); Text("回看一局，读懂一步。").font(.system(size: 30, weight: .medium, design: .serif)); Text(game.name).font(.system(size: 12)).foregroundStyle(Theme.muted) }
                Spacer()
                ExportMenu(record: game).font(.system(size: 12)).frame(width: 72)
                if !game.ended { Button("继续对弈") { model.resume() }.buttonStyle(SoftButton(prominent: true)).disabled(model.isBusy).help("从棋谱的最后一手继续对弈") }
            }
            HStack(alignment: .top, spacing: 24) {
                VStack(spacing: 16) {
                    HStack { Text(game.kind.title).font(.system(size: 13, weight: .semibold)); Spacer(); Text(index == 0 ? "初始局面" : "第 \(index) 手 · \(game.moves[index - 1].notation)").font(.system(size: 12)).foregroundStyle(Theme.muted) }
                    BoardView(kind: game.kind, size: game.size, position: game.positions[index], lastMove: index > 0 ? game.moves[index - 1].code : nil, hintCode: game.analyses[index]?.moveCode, interactive: false)
                        .frame(minHeight: 350, maxHeight: .infinity)
                    HStack(spacing: 12) {
                        SmallIconButton(symbol: "backward.end", label: "回到开局") { model.seek(0) }.disabled(index == 0)
                        Button { model.seek(index - 1) } label: { Image(systemName: "chevron.left").frame(width: 36, height: 34) }.buttonStyle(.plain).background(Theme.pale, in: RoundedRectangle(cornerRadius: 8)).keyboardShortcut(.leftArrow, modifiers: []).disabled(index == 0).help("上一手（←）").accessibilityLabel("上一手")
                        Slider(value: Binding(get: { Double(model.reviewIndex) }, set: { model.seek(Int($0)) }), in: 0...Double(max(1, game.moves.count)), step: 1).disabled(game.moves.isEmpty).accessibilityLabel("复盘进度")
                        Button { model.seek(index + 1) } label: { Image(systemName: "chevron.right").frame(width: 36, height: 34) }.buttonStyle(.plain).background(Theme.pale, in: RoundedRectangle(cornerRadius: 8)).keyboardShortcut(.rightArrow, modifiers: []).disabled(index == game.moves.count).help("下一手（→）").accessibilityLabel("下一手")
                        SmallIconButton(symbol: "forward.end", label: "到最新局面") { model.seek(game.moves.count) }.disabled(index == game.moves.count)
                    }
                    Text("\(index) / \(game.moves.count) 手 · 可使用左右方向键逐步回看").font(.system(size: 11)).foregroundStyle(Theme.muted)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
                VStack(spacing: 16) {
                    Card {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack { Label("局面分析", systemImage: "sparkle.magnifyingglass").font(.system(size: 14, weight: .semibold)); Spacer(); if model.isBusy { ProgressView().controlSize(.small) } }
                            if let analysis = game.analyses[index] {
                                Text(scoreText(analysis, game: game)).font(.system(size: 24, weight: .medium, design: .serif)).foregroundStyle(Theme.accent)
                                Text("建议：\(analysis.suggestion)").font(.system(size: 13, weight: .medium))
                                Text(analysis.detail).font(.system(size: 11)).lineSpacing(4).foregroundStyle(Theme.muted).fixedSize(horizontal: false, vertical: true)
                            } else {
                                Text("这一手，还可以怎么走？").font(.system(size: 16, weight: .medium, design: .serif))
                                Text("让本地引擎评估当前局面，并给出下一手建议。").font(.system(size: 12)).foregroundStyle(Theme.muted).lineSpacing(4).fixedSize(horizontal: false, vertical: true)
                            }
                            Button(game.analyses[index] == nil ? "分析当前局面" : "重新分析") { model.analyseReview() }.buttonStyle(SoftButton(prominent: true)).disabled(model.isBusy)
                            if model.isBusy { Text(model.busy).font(.system(size: 10)).foregroundStyle(Theme.muted) }
                        }
                    }
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack { Text("棋谱导航").font(.system(size: 14, weight: .semibold)); Spacer(); Text(game.resultTitle).font(.system(size: 11)).foregroundStyle(Theme.muted) }
                            MoveList(record: game, selected: index, onSelect: model.seek).frame(minHeight: 105, maxHeight: .infinity)
                        }
                    }.frame(maxHeight: .infinity)
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack { Text("评估轨迹").font(.system(size: 12, weight: .semibold)); Spacer(); Text("\(game.analyses.count) 个局面").font(.system(size: 10)).foregroundStyle(Theme.muted) }
                            if game.analyses.isEmpty {
                                Text("逐手分析后，评估会记录在这里。").font(.system(size: 11)).foregroundStyle(Theme.muted).frame(height: 55)
                            } else {
                                EvaluationPlot(game: game, selected: index).frame(height: 65)
                                Text("上方有利于\(game.kind.firstSide.name(in: game.kind)) · 仅显示已分析局面").font(.system(size: 9)).foregroundStyle(Theme.muted)
                            }
                        }
                    }
                }.frame(width: 290)
            }.frame(maxHeight: .infinity)
            Text(game.ended ? "\(game.resultTitle) · \(game.resultDetail)" : "复盘不会改变原棋谱。选择“继续对弈”会回到最新局面。").font(.system(size: 11)).foregroundStyle(Theme.muted)
        }.padding(30)
    }
    private func scoreText(_ analysis: Analysis, game: GameRecord) -> String {
        if let mate = analysis.mate {
            if mate == 0 { return "终局" }
            return "\(mate > 0 ? game.kind.firstSide.name(in: game.kind) : game.kind.firstSide.opposite.name(in: game.kind)) \(abs(mate)) 步内将杀"
        }
        if abs(analysis.value) < 0.05 { return "局面接近均衡" }
        let side = analysis.value > 0 ? game.kind.firstSide : game.kind.firstSide.opposite
        return "\(side.name(in: game.kind)) +\(String(format: "%.1f", abs(analysis.value)))\(game.kind == .go ? " 目" : "")"
    }
}

private struct EvaluationPlot: View {
    let game: GameRecord
    let selected: Int
    var body: some View {
        Canvas { context, size in
            var zero = Path(); zero.move(to: CGPoint(x: 0, y: size.height / 2)); zero.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            context.stroke(zero, with: .color(Theme.border), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            let scale = max(3.0, game.analyses.values.map { min(abs($0.value), 20) }.max() ?? 3)
            for (index, value) in game.analyses {
                let x = 5 + (size.width - 10) * Double(index) / Double(max(1, game.moves.count))
                let y = size.height / 2 - (size.height / 2 - 6) * max(-1, min(1, value.value / scale))
                context.fill(Path(ellipseIn: CGRect(x: x - 3, y: y - 3, width: 6, height: 6)), with: .color(index == selected ? Theme.gold : Theme.accent))
            }
        }.accessibilityLabel("已分析 \(game.analyses.count) 个局面，详细评估请通过棋谱导航查看")
    }
}
