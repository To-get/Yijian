import SwiftUI
import YijianCore

struct PlayView: View {
    @EnvironmentObject private var model: AppModel
    @ViewState private var flipped = false
    var body: some View {
        VStack(alignment: .leading, spacing: 21) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "PLAY / LEARN / GROW")
                    Text("落一子，进一步。").font(.system(size: 30, weight: .medium, design: .serif))
                    Text("与 AI 从容对弈，让每一局都有新的收获。").font(.system(size: 12)).foregroundStyle(Theme.muted)
                }
                Spacer()
                Button { model.configure() } label: { Label("新对局", systemImage: "plus") }.buttonStyle(SoftButton(prominent: true)).disabled(model.isBusy)
            }
            HStack(spacing: 10) {
                ForEach(GameKind.allCases) { kind in
                    Button { if kind != model.record.kind { model.configure(kind) } } label: {
                        HStack(spacing: 8) {
                            Text(kind == .chess ? "♞" : kind == .xiangqi ? "将" : "●").font(.system(size: 17, weight: .medium, design: .serif))
                            Text(kind.title).font(.system(size: 12, weight: .semibold))
                        }.padding(.horizontal, 18).frame(height: 38)
                    }.buttonStyle(.plain).background(model.record.kind == kind ? Theme.ink : Theme.paper, in: RoundedRectangle(cornerRadius: 9)).foregroundStyle(model.record.kind == kind ? Color.white : Theme.muted).overlay(RoundedRectangle(cornerRadius: 9).stroke(model.record.kind == kind ? Theme.ink : Theme.border, lineWidth: 1)).disabled(model.isBusy)
                }
                Spacer()
                Text(model.record.kind == .go ? "\(model.record.size) 路 · 中国规则 · 贴 7.5" : "自由练习 · 不限时").font(.system(size: 11)).foregroundStyle(Theme.muted)
            }
            HStack(alignment: .top, spacing: 24) {
                VStack(spacing: 12) {
                    playerRow(side: model.record.humanSide.opposite, computer: true)
                    BoardView(kind: model.record.kind, size: model.record.size, position: model.record.current, lastMove: model.record.moves.last?.code, selection: model.selection, targets: model.targets, hintCode: model.hint?.moveCode, flipped: flipped != (model.record.humanSide != model.record.kind.firstSide), interactive: model.canPlay, onTap: model.tap)
                        .frame(maxWidth: .infinity, maxHeight: .infinity).frame(minHeight: 330)
                    playerRow(side: model.record.humanSide, computer: false)
                    HStack(spacing: 10) {
                        SmallIconButton(symbol: "arrow.uturn.backward", label: "悔棋（⌘Z）", action: model.undo).disabled(!model.canUndo)
                        SmallIconButton(symbol: "arrow.triangle.2.circlepath", label: "翻转棋盘") { flipped.toggle() }
                        SmallIconButton(symbol: "lightbulb", label: "查看建议", action: model.requestHint).disabled(!model.canPlay)
                        if model.record.kind == .go {
                            Button("停一手") { model.play(LegalMove(code: "pass", notation: "停一手")) }.buttonStyle(SoftButton()).disabled(!model.canPlay)
                        }
                        Spacer()
                        Button("认输") { model.showResign = true }.buttonStyle(.plain).font(.system(size: 11)).foregroundStyle(Theme.muted).disabled(model.isBusy || model.record.ended)
                        Button { model.review() } label: { Label("复盘", systemImage: "arrow.counterclockwise") }.buttonStyle(SoftButton()).disabled(model.isBusy)
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
                VStack(spacing: 16) {
                    Card {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack { Eyebrow(text: "YOUR PRACTICE PARTNER"); Spacer(); Image(systemName: "cpu").foregroundStyle(Theme.accent) }
                            HStack(alignment: .firstTextBaseline) { Text("\(model.record.difficulty.title)陪练").font(.system(size: 22, weight: .medium, design: .serif)); Spacer(); Text("Lv. \(model.record.difficulty.rawValue + 1)").font(.system(size: 11, design: .monospaced)).foregroundStyle(Theme.muted) }
                            HStack(spacing: 5) { ForEach(0..<4) { i in RoundedRectangle(cornerRadius: 2).fill(i <= model.record.difficulty.rawValue ? Theme.accent : Theme.border).frame(height: 4) } }
                            Text(model.record.difficulty.detail).font(.system(size: 12)).foregroundStyle(Theme.muted)
                            Divider()
                            HStack(spacing: 8) {
                                if model.isBusy { ProgressView().controlSize(.small) }
                                else { Circle().fill(model.record.ended ? Theme.gold : Theme.accent).frame(width: 7, height: 7) }
                                Text(model.status).font(.system(size: 12, weight: .medium)).fixedSize(horizontal: false, vertical: true)
                            }.frame(minHeight: 18)
                            if model.record.ended {
                                Text(model.record.resultDetail).font(.system(size: 11)).foregroundStyle(Theme.muted).fixedSize(horizontal: false, vertical: true)
                                Button("回看这局棋") { model.review() }.buttonStyle(SoftButton(prominent: true))
                            }
                        }
                    }
                    Card {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack { Text("本局棋谱").font(.system(size: 14, weight: .semibold)); Spacer(); Text("\(model.record.moves.count) 手").font(.system(size: 11, design: .monospaced)).foregroundStyle(Theme.muted) }
                            MoveList(record: model.record, selected: model.record.moves.count) { index in model.review(); model.seek(index) }.frame(minHeight: 118, maxHeight: .infinity).disabled(model.isBusy)
                            HStack {
                                Button { model.save() } label: { Label("保存", systemImage: "square.and.arrow.down") }.buttonStyle(.plain)
                                Spacer()
                                ExportMenu(record: model.record)
                            }.font(.system(size: 11)).foregroundStyle(Theme.accent)
                        }
                    }.frame(maxHeight: .infinity)
                    Card {
                        VStack(alignment: .leading, spacing: 9) {
                            Label(model.hint == nil ? "落子小提示" : "建议着法：\(model.hint!.suggestion)", systemImage: "lightbulb").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.accent)
                            Text(model.hint?.detail ?? (model.record.kind == .go ? "先看气与连接，再考虑围地。棋子落下后不移动。" : "点击己方棋子查看合法落点，再点击目标位置落子。"))
                                .font(.system(size: 11)).lineSpacing(4).foregroundStyle(Theme.muted).fixedSize(horizontal: false, vertical: true)
                            if model.hint == nil { Button("去入门学堂 →") { model.learnKind = model.record.kind; model.screen = .learn }.buttonStyle(.plain).font(.system(size: 11)).foregroundStyle(Theme.accent) }
                        }
                    }
                }.frame(width: 280).frame(maxHeight: .infinity)
            }.frame(maxHeight: .infinity)
            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield").font(.system(size: 10))
                Text(model.notice.isEmpty ? "每一步自动保存 · 随时回来，接着下" : model.notice).font(.system(size: 11))
                Spacer()
                Text(model.record.kind.english).font(.system(size: 9, design: .monospaced)).tracking(2)
            }.foregroundStyle(Theme.muted).frame(height: 16)
        }.padding(.horizontal, 30).padding(.top, 25).padding(.bottom, 20)
    }
    private func playerRow(side: Side, computer: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: computer ? "cpu" : "person.crop.circle").font(.system(size: 18)).foregroundStyle(Theme.accent).frame(width: 36, height: 36).background(Theme.pale, in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 3) {
                Text(computer ? "弈间 AI" : "你").font(.system(size: 13, weight: .semibold))
                Text(computer ? "\(model.record.kind.engine) · \(model.record.difficulty.title)" : "专注当下这一手").font(.system(size: 10)).foregroundStyle(Theme.muted)
            }
            Spacer()
            if model.record.kind == .go { Text("提子 \(side == .black ? model.record.current.blackCaptures : model.record.current.whiteCaptures)").font(.system(size: 10)).foregroundStyle(Theme.muted) }
            Text(side.name(in: model.record.kind)).font(.system(size: 11, weight: .medium)).padding(.horizontal, 12).padding(.vertical, 6).background(Theme.paper, in: Capsule()).overlay(Capsule().stroke(Theme.border, lineWidth: 1))
        }.padding(.horizontal, 4)
    }
}

struct MoveList: View {
    let record: GameRecord
    let selected: Int
    let onSelect: (Int) -> Void
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if record.moves.isEmpty {
                    VStack(spacing: 10) { Image(systemName: "text.alignleft").font(.system(size: 22, weight: .light)); Text("棋谱从第一手开始").font(.system(size: 12)); Text("落子后会自动记录在这里").font(.system(size: 10)) }.foregroundStyle(Theme.muted).frame(maxWidth: .infinity).padding(.vertical, 28)
                } else {
                    LazyVStack(spacing: 4) {
                        ForEach(0..<((record.moves.count + 1) / 2), id: \.self) { row in
                            HStack(spacing: 5) {
                                Text("\(row + 1)").font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.muted).frame(width: 24)
                                moveButton(row * 2)
                                if row * 2 + 1 < record.moves.count { moveButton(row * 2 + 1) } else { Color.clear.frame(maxWidth: .infinity, minHeight: 30) }
                            }.id(row)
                        }
                    }
                }
            }.onChange(of: selected) { value in if value > 0 { proxy.scrollTo((value - 1) / 2, anchor: .center) } }
                .onAppear { if selected > 0 { proxy.scrollTo((selected - 1) / 2, anchor: .center) } }
        }
    }
    private func moveButton(_ index: Int) -> some View {
        Button { onSelect(index + 1) } label: {
            Text(record.moves[index].notation).font(.system(size: 12, weight: selected == index + 1 ? .semibold : .regular, design: record.kind == .xiangqi ? .default : .monospaced)).frame(maxWidth: .infinity, minHeight: 30).contentShape(Rectangle())
        }.buttonStyle(.plain).background(selected == index + 1 ? Theme.pale : Color.clear, in: RoundedRectangle(cornerRadius: 5)).accessibilityLabel("第 \(index + 1) 手 \(record.moves[index].notation)")
    }
}
struct ExportMenu: View {
    @EnvironmentObject private var model: AppModel
    let record: GameRecord
    var body: some View {
        Menu {
            Button("弈间棋谱（可重新打开）") { model.export(record) }
            if record.kind != .xiangqi { Button(record.kind == .go ? "SGF 标准棋谱" : "PGN 标准棋谱") { model.export(record, standard: true) } }
        } label: { Label("导出", systemImage: "square.and.arrow.up") }.menuStyle(.borderlessButton).fixedSize()
    }
}
