import AppKit
import SwiftTerm

/// Hosts a single terminal view running the editor and exits when it quits.
@MainActor
final class HatAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, @preconcurrency LocalProcessTerminalViewDelegate {
    private let config: LaunchConfig
    private var window: NSWindow!
    private var terminal: LocalProcessTerminalView!
    private var didStartProcess = false

    init(config: LaunchConfig) {
        self.config = config
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentRect = NSRect(x: 0, y: 0, width: 920, height: 600)

        terminal = LocalProcessTerminalView(frame: contentRect)
        terminal.processDelegate = self
        terminal.font = NSFont.monospacedSystemFont(ofSize: config.fontSize, weight: .regular)
        terminal.autoresizingMask = [.width, .height]

        window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = defaultTitle()
        window.contentView = terminal
        window.delegate = self
        window.center()
        window.setFrameAutosaveName("vim-with-a-hat-main")
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(terminal)

        setupMenu()
        NSApp.activate(ignoringOtherApps: true)

        startEditor()
    }

    private func startEditor() {
        guard !didStartProcess else { return }
        didStartProcess = true

        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["COLORTERM"] = "truecolor"
        let envArray = env.map { "\($0.key)=\($0.value)" }

        terminal.startProcess(
            executable: config.editor,
            args: config.files,
            environment: envArray,
            execName: nil
        )
    }

    private func defaultTitle() -> String {
        if let first = config.files.first {
            let name = (first as NSString).lastPathComponent
            return config.files.count > 1 ? "\(name) (+\(config.files.count - 1))" : name
        }
        return "vim-with-a-hat"
    }

    // A minimal menu so Cmd-Q / Cmd-W behave like a normal mac app.
    private func setupMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        appItem.submenu = appMenu
        NSApp.mainMenu = mainMenu
    }

    // MARK: LocalProcessTerminalViewDelegate

    func processTerminated(source: TerminalView, exitCode: Int32?) {
        // SwiftTerm's PTY path hands us waitpid(2)'s raw status, not a decoded
        // exit code (e.g. 1792 == 7 << 8). Decode it so `vh` mirrors the editor.
        exit(exitCode.map(Self.decodeWaitStatus) ?? 0)
    }

    static func decodeWaitStatus(_ status: Int32) -> Int32 {
        let lowSeven = status & 0x7f
        if lowSeven == 0 { return (status >> 8) & 0xff } // WIFEXITED → WEXITSTATUS
        if lowSeven == 0x7f { return 0 }                 // WIFSTOPPED → not a real exit
        return 128 + lowSeven                            // WIFSIGNALED → 128 + signal
    }

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        if !title.isEmpty {
            window.title = title
        }
    }

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

    // MARK: NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // Closing the window ends the session; the PTY closes and the editor
        // receives SIGHUP. Exit promptly so `vh` returns.
        exit(0)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
