import SwiftUI
import YijianCore

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    private var appVersion: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "开发版" }
    var body: some View {
        HStack(spacing: 0) {
            sidebar
            VStack(spacing: 0) {
                HStack {
                    Text("弈间 / \(model.screen.rawValue)").font(.system(size: 12)).foregroundStyle(Theme.muted)
                    Spacer()
                    Circle().fill(Theme.accent).frame(width: 6, height: 6)
                    Text("本地对弈 · 无需联网").font(.system(size: 11)).foregroundStyle(Theme.muted)
                }.padding(.horizontal, 32).frame(height: 56)
                Rectangle().fill(Theme.border).frame(height: 1)
                Group {
                    switch model.screen {
                    case .play: PlayView()
                    case .learn: LearnView()
                    case .library: LibraryView()
                    case .review: ReviewView()
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
                if let error = model.error {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle")
                        Text(error).font(.system(size: 12)).fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Button("重试") { model.retry() }.disabled(model.isBusy || model.screen != .play)
                        Button("关闭") { model.error = nil }
                    }.foregroundStyle(Color(hex: 0x953F31)).padding(14).background(Color(hex: 0xFAEAE3))
                }
            }
        }
        .background(Theme.background).foregroundStyle(Theme.ink).tint(Theme.accent)
        .sheet(isPresented: $model.showNewGame) { NewGameSheet() }
        .sheet(isPresented: $model.showAbout) { about }
        .sheet(isPresented: Binding(get: { !model.promotions.isEmpty }, set: { if !$0 { model.promotions = [] } })) {
            VStack(spacing: 22) {
                Text("兵已到底，选择升变").font(.title2.bold())
                HStack(spacing: 16) {
                    ForEach(model.promotions, id: \.code) { move in
                        let piece = String(move.code.last ?? "q")
                        Button { model.play(move) } label: {
                            VStack { PieceView(kind: .chess, piece: model.record.humanSide == .white ? piece.uppercased() : piece, size: 64); Text(PieceView.name(piece, kind: .chess)) }
                        }.buttonStyle(SoftButton()).accessibilityLabel("升变为\(PieceView.name(piece, kind: .chess))")
                    }
                }
                Button("返回棋盘") { model.promotions = [] }
            }.padding(36)
        }
        .confirmationDialog("确认认输并结束本局？棋谱会自动保存。", isPresented: $model.showResign, titleVisibility: .visible) { Button("认输", role: .destructive) { model.resign() }; Button("继续下棋", role: .cancel) {} }
    }
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11).fill(Color.white.opacity(0.12)).frame(width: 43, height: 43)
                    Image(systemName: "circle.grid.cross").font(.system(size: 25, weight: .light))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("弈间").font(.system(size: 25, weight: .medium, design: .serif)).tracking(4)
                    Text("Y I J I A N").font(.system(size: 8, weight: .medium)).foregroundStyle(Color.white.opacity(0.65))
                }
            }.padding(.top, 48).padding(.bottom, 42).padding(.horizontal, 22)
            Text("你的研习室").font(.system(size: 10)).tracking(2).foregroundStyle(Color.white.opacity(0.6)).padding(.horizontal, 24).padding(.bottom, 14)
            ForEach(Screen.allCases, id: \.self) { screen in
                Button {
                    if screen == .review { model.review() } else { model.screen = screen }
                } label: {
                    HStack(spacing: 13) {
                        Image(systemName: screen.symbol).font(.system(size: 17, weight: .regular)).frame(width: 23)
                        Text(screen.rawValue).font(.system(size: 14, weight: model.screen == screen ? .semibold : .regular))
                        Spacer()
                        if model.screen == screen { Circle().fill(Color(hex: 0xD6CF9E)).frame(width: 5, height: 5) }
                    }.padding(.horizontal, 14).frame(height: 46).contentShape(Rectangle())
                }.buttonStyle(.plain).foregroundStyle(Color.white.opacity(model.screen == screen ? 1 : 0.72))
                    .background(model.screen == screen ? Color.white.opacity(0.1) : Color.clear, in: RoundedRectangle(cornerRadius: 9)).padding(.horizontal, 12).padding(.bottom, 6).disabled(screen == .review && model.isBusy)
            }
            Spacer(minLength: 32)
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "leaf").font(.system(size: 20, weight: .light)).foregroundStyle(Color(hex: 0xD6CF9E))
                Text("不急于赢，\n先享受每一步。").font(.system(size: 16, weight: .regular, design: .serif)).lineSpacing(7)
                Text("三种棋，一处静心之所。").font(.system(size: 10)).foregroundStyle(Color.white.opacity(0.6))
            }.padding(22)
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1).padding(.horizontal, 22)
            Button { model.showAbout = true } label: {
                HStack { Image(systemName: "info.circle"); Text("关于弈间"); Spacer(); Text(appVersion).font(.system(size: 10, design: .monospaced)) }.font(.system(size: 11)).padding(22)
            }.buttonStyle(.plain).foregroundStyle(Color.white.opacity(0.65))
        }.frame(width: 194).frame(maxHeight: .infinity).foregroundStyle(.white).background(Theme.ink)
    }
    private var about: some View {
        VStack(alignment: .leading, spacing: 18) {
            Eyebrow(text: "YIJIAN / BUILT FOR PRACTICE")
            Text("弈间 · 三棋研习室").font(.system(size: 28, weight: .medium, design: .serif))
            Text("原生 macOS 离线应用 · 版本 \(appVersion)").foregroundStyle(Theme.muted)
            Divider()
            Text("国际象棋与中国象棋使用 Fairy-Stockfish；围棋使用 GNU Go 3.8。四档难度调整引擎的搜索参数，不对应实际等级分或段位。围棋自动数子含死活估计，适合练习。")
            HStack { Link("Fairy-Stockfish", destination: URL(string: "https://github.com/fairy-stockfish/Fairy-Stockfish")!); Link("GNU Go", destination: URL(string: "https://www.gnu.org/software/gnugo/")!) }
            Text("应用只在本地保存棋谱。项目采用 GPL-3.0-or-later；项目许可证、两个引擎的许可证、源码归档与修改脚本随应用附带于 Contents/Resources/OpenSource。")
            Text("棋谱目录：\(model.library.directory.path)").font(.system(size: 11, design: .monospaced)).textSelection(.enabled)
            HStack { Spacer(); Button("回到研习室") { model.showAbout = false }.buttonStyle(SoftButton(prominent: true)) }
        }.font(.system(size: 13)).lineSpacing(5).foregroundStyle(Theme.ink).padding(32).frame(width: 560).background(Theme.background)
    }
}

struct NewGameSheet: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Eyebrow(text: "A NEW BEGINNING")
            Text("开始一局新的练习").font(.system(size: 28, weight: .medium, design: .serif))
            Text("已有落子的棋局会保留在“我的棋谱”中。").font(.system(size: 12)).foregroundStyle(Theme.muted)
            VStack(alignment: .leading, spacing: 12) {
                Text("选择棋类").font(.system(size: 13, weight: .semibold))
                Picker("棋类", selection: $model.setupKind) { ForEach(GameKind.allCases) { Text($0.title).tag($0) } }.pickerStyle(.segmented).labelsHidden()
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("陪练难度").font(.system(size: 13, weight: .semibold))
                HStack(spacing: 9) {
                    ForEach(Difficulty.allCases) { level in
                        Button { model.setupDifficulty = level } label: {
                            VStack(spacing: 9) { Image(systemName: "circle.grid.2x2.fill").font(.system(size: 16)).opacity(Double(level.rawValue + 1) / 4); Text(level.title).font(.system(size: 13, weight: .semibold)) }.frame(maxWidth: .infinity).padding(.vertical, 16)
                        }.buttonStyle(.plain).background(model.setupDifficulty == level ? Theme.pale : Theme.paper, in: RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(model.setupDifficulty == level ? Theme.accent : Theme.border, lineWidth: 1))
                    }
                }
                Text("\(model.setupDifficulty.detail) · 档位不对应实际等级分或段位").font(.system(size: 11)).foregroundStyle(Theme.muted)
            }
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("你的执子").font(.system(size: 13, weight: .semibold))
                    Picker("执子", selection: $model.setupFirst) { Text("先手 · \(model.setupKind.firstSide.name(in: model.setupKind))").tag(true); Text("后手 · \(model.setupKind.firstSide.opposite.name(in: model.setupKind))").tag(false) }.labelsHidden()
                }
                if model.setupKind == .go {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("棋盘大小").font(.system(size: 13, weight: .semibold))
                        Picker("棋盘大小", selection: $model.setupSize) { Text("9 路 · 入门推荐").tag(9); Text("13 路").tag(13); Text("19 路").tag(19) }.labelsHidden()
                    }
                }
            }
            HStack { Button("取消") { model.showNewGame = false }.buttonStyle(SoftButton()); Spacer(); Button { model.start() } label: { Label("摆好棋盘，开始", systemImage: "arrow.right") }.buttonStyle(SoftButton(prominent: true)).keyboardShortcut(.defaultAction) }
        }.padding(32).frame(width: 510).foregroundStyle(Theme.ink).background(Theme.background)
    }
}
