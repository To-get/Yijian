import SwiftUI
import YijianCore

struct LearnView: View {
    @EnvironmentObject private var model: AppModel
    @ViewState private var lesson: Lesson?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "LEARN / ONE STEP AT A TIME")
                    Text("一局之前，先懂一步。").font(.system(size: 32, weight: .medium, design: .serif))
                    Text("从零开始认识棋子、规则与思路。读一小节，做一道题，再到棋盘上试试。").font(.system(size: 13)).foregroundStyle(Theme.muted)
                }
                HStack(spacing: 12) {
                    ForEach(GameKind.allCases) { kind in
                        Button { model.learnKind = kind } label: {
                            VStack(alignment: .leading, spacing: 13) {
                                HStack { Text(kind.english).font(.system(size: 10, design: .monospaced)).tracking(2); Spacer(); Image(systemName: model.learnKind == kind ? "checkmark.circle.fill" : "circle") }
                                Text(kind.title).font(.system(size: 23, weight: .medium, design: .serif))
                                Text(kind.subtitle).font(.system(size: 11))
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(22).contentShape(Rectangle())
                        }.buttonStyle(.plain).foregroundStyle(model.learnKind == kind ? Color.white : Theme.ink).background(model.learnKind == kind ? Theme.accent : Theme.paper, in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(model.learnKind == kind ? Theme.accent : Theme.border, lineWidth: 1))
                    }
                }
                HStack {
                    Text("\(model.learnKind.title) · 入门路径").font(.system(size: 18, weight: .medium))
                    Spacer()
                    let lessons = Lessons.forGame(model.learnKind)
                    Text("已完成 \(lessons.filter { model.completed.contains($0.id) }.count) / \(lessons.count)").font(.system(size: 12)).foregroundStyle(Theme.muted)
                }
                ForEach(Array(Lessons.forGame(model.learnKind).enumerated()), id: \.element.id) { index, item in
                    Button { lesson = item } label: {
                        HStack(spacing: 24) {
                            Text(String(format: "%02d", index + 1)).font(.system(size: 34, weight: .light, design: .serif)).foregroundStyle(Theme.accent).frame(width: 60, height: 64).background(Theme.pale, in: RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 9) {
                                Text(item.title).font(.system(size: 19, weight: .medium, design: .serif))
                                Text(item.summary).font(.system(size: 12)).foregroundStyle(Theme.muted)
                                Text("\(item.steps.count) 个小节 · 互动小测验").font(.system(size: 10)).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            if model.completed.contains(item.id) { Label("已学完", systemImage: "checkmark.circle.fill").font(.system(size: 12)).foregroundStyle(Theme.accent) }
                            Image(systemName: "arrow.up.right").foregroundStyle(Theme.accent)
                        }.padding(24).contentShape(Rectangle())
                    }.buttonStyle(.plain).background(Theme.paper, in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1))
                }
                HStack {
                    VStack(alignment: .leading, spacing: 7) { Text("学一点，就去下一局。").font(.system(size: 18, weight: .medium, design: .serif)); Text("启蒙陪练和走子提示会陪你迈出第一步。").font(.system(size: 12)).foregroundStyle(Theme.muted) }
                    Spacer()
                    Button("去棋盘试试 →") { model.configure(model.learnKind); model.setupDifficulty = .gentle }.buttonStyle(SoftButton(prominent: true)).disabled(model.isBusy)
                }.padding(24).background(Theme.pale, in: RoundedRectangle(cornerRadius: 14))
            }.padding(32)
        }.sheet(item: $lesson) { LessonSheet(lesson: $0) }
    }
}

private struct LessonSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let lesson: Lesson
    @ViewState private var index = 0
    @ViewState private var choice: Int?
    private var step: LessonStep { lesson.steps[index] }
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack { Eyebrow(text: "\(index + 1) / \(lesson.steps.count)  ·  \(lesson.title)"); Spacer(); SmallIconButton(symbol: "xmark", label: "关闭教程") { dismiss() } }
            HStack(spacing: 5) { ForEach(lesson.steps.indices, id: \.self) { i in Capsule().fill(i <= index ? Theme.accent : Theme.border).frame(height: 3) } }
            Text(step.title).font(.system(size: 28, weight: .medium, design: .serif))
            Text(step.body).font(.system(size: 15)).lineSpacing(9).fixedSize(horizontal: false, vertical: true)
            Divider().padding(.vertical, 4)
            Label("想一想：\(step.question)", systemImage: "lightbulb").font(.system(size: 14, weight: .semibold))
            VStack(spacing: 8) {
                ForEach(step.answers.indices, id: \.self) { answer in
                    Button { choice = answer } label: {
                        HStack { Text(step.answers[answer]); Spacer(); Image(systemName: choice == answer ? (answer == step.correct ? "checkmark.circle.fill" : "xmark.circle") : "circle") }.font(.system(size: 13)).padding(15).contentShape(Rectangle())
                    }.buttonStyle(.plain).background(choice == answer ? Theme.pale : Theme.paper, in: RoundedRectangle(cornerRadius: 9)).overlay(RoundedRectangle(cornerRadius: 9).stroke(choice == answer ? Theme.accent : Theme.border, lineWidth: 1))
                }
            }
            if let choice {
                Text((choice == step.correct ? "答对了。" : "再想一想。") + step.explanation).font(.system(size: 12)).foregroundStyle(Theme.accent).lineSpacing(5).fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Button("上一节") { index -= 1; choice = nil }.buttonStyle(SoftButton()).disabled(index == 0)
                Spacer()
                Button(index == lesson.steps.count - 1 ? "完成这课" : "下一节 →") {
                    if index == lesson.steps.count - 1 { model.markCompleted(lesson.id); dismiss() }
                    else { index += 1; choice = nil }
                }.buttonStyle(SoftButton(prominent: true)).disabled(choice != step.correct)
            }
        }.padding(32).frame(width: 600).foregroundStyle(Theme.ink).background(Theme.background)
    }
}
