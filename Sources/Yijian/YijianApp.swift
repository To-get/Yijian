import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"), let icon = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = icon
        }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main struct YijianApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = AppModel()
    var body: some Scene {
        Window("弈间 · 三棋研习室", id: "main") {
            RootView().environmentObject(model).preferredColorScheme(.light)
                .frame(minWidth: 1080, minHeight: 760)
                .task { model.bootstrap() }
        }
        .defaultSize(width: 1320, height: 880).windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("新对局") { model.configure() }.keyboardShortcut("n").disabled(model.isBusy)
                Button("导入棋谱…") { model.importGame() }.keyboardShortcut("o").disabled(model.isBusy)
            }
            CommandGroup(replacing: .saveItem) {
                Button("保存棋谱") { model.save() }.keyboardShortcut("s")
                Button("导出棋谱…") { model.export(model.screen == .review ? model.reviewRecord ?? model.record : model.record) }.keyboardShortcut("s", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .appInfo) { Button("关于弈间") { model.showAbout = true } }
            CommandMenu("对弈") {
                Button("悔棋") { model.undo() }.keyboardShortcut("z").disabled(!model.canUndo)
                Button("查看建议") { model.requestHint() }.keyboardShortcut("h", modifiers: [.command, .shift]).disabled(!model.canPlay)
                Button("复盘当前棋局") { model.review() }.keyboardShortcut("r").disabled(model.isBusy)
            }
        }
    }
}
