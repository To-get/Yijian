import SwiftUI
import YijianCore

struct LibraryView: View {
    @EnvironmentObject private var model: AppModel
    @ViewState private var filter: GameKind?
    @ViewState private var search = ""
    private var games: [GameRecord] { model.records.filter { (filter == nil || $0.kind == filter) && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)) } }
    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            HStack {
                VStack(alignment: .leading, spacing: 9) { Eyebrow(text: "YOUR PERSONAL GAME LIBRARY"); Text("每一局，都值得留下。").font(.system(size: 30, weight: .medium, design: .serif)); Text("回看走过的路，也看见自己的进步。").font(.system(size: 12)).foregroundStyle(Theme.muted) }
                Spacer()
                Button { model.importGame() } label: { Label("导入棋谱", systemImage: "square.and.arrow.down") }.buttonStyle(SoftButton()).disabled(model.isBusy)
            }
            HStack {
                Picker("筛选棋类", selection: $filter) { Text("全部").tag(nil as GameKind?); ForEach(GameKind.allCases) { Text($0.title).tag(Optional($0)) } }.pickerStyle(.segmented).frame(width: 370).labelsHidden()
                Spacer()
                TextField("搜索棋谱名称", text: $search).textFieldStyle(.roundedBorder).frame(width: 200).accessibilityLabel("搜索棋谱")
            }
            if games.isEmpty {
                VStack(spacing: 18) {
                    Image(systemName: search.isEmpty ? "tray" : "magnifyingglass").font(.system(size: 42, weight: .ultraLight)).foregroundStyle(Theme.accent)
                    Text(search.isEmpty && filter == nil ? "你的第一份棋谱，从一局练习开始" : "没有找到匹配的棋谱").font(.system(size: 19, weight: .medium, design: .serif))
                    Text("所有对局自动保存在这台 Mac 上，也可导出备份。").font(.system(size: 12)).foregroundStyle(Theme.muted)
                    Button("开始练习") { model.configure(filter) }.buttonStyle(SoftButton(prominent: true)).disabled(model.isBusy)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(games) { game in
                            HStack(spacing: 20) {
                                Text(game.kind == .chess ? "♞" : game.kind == .xiangqi ? "将" : "●").font(.system(size: 31, weight: .regular, design: .serif)).foregroundStyle(Theme.accent).frame(width: 66, height: 66).background(Theme.pale, in: RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 9) {
                                    Text(game.name).font(.system(size: 16, weight: .medium))
                                    HStack(spacing: 10) { Text(game.createdAt, format: .dateTime.year().month().day().hour().minute()); Text("\(game.moves.count) 手"); Text("你执\(game.humanSide.name(in: game.kind))") }.font(.system(size: 11)).foregroundStyle(Theme.muted)
                                }
                                Spacer()
                                Text(game.resultTitle).font(.system(size: 11)).padding(.horizontal, 10).padding(.vertical, 6).background(Theme.pale, in: Capsule())
                                Button("打开复盘") { model.review(game) }.buttonStyle(SoftButton()).disabled(model.isBusy)
                                ExportMenu(record: game).font(.system(size: 11)).frame(width: 54)
                            }.padding(20).background(Theme.paper, in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1))
                        }
                    }
                }
            }
            Text("\(games.count) 份棋谱 · 导入支持 .yijian；导出支持完整棋谱，另提供国际象棋 PGN 与围棋 SGF。").font(.system(size: 11)).foregroundStyle(Theme.muted)
        }.padding(32)
    }
}
