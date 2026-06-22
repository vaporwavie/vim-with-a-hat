import Foundation

let hatVersion = "0.1.0"

struct LaunchConfig {
    var editor: String
    var files: [String]
    var fontSize: CGFloat
}

enum ParseResult {
    case run(LaunchConfig)
    case help
    case version
    case failure(String)
}

let helpText = """
vim-with-a-hat \(hatVersion) — a tiny native GUI hat for vim/nvim.

USAGE:
    vh [OPTIONS] [FILE...]

    Opens a native macOS window running vim/nvim over the given file(s).
    With no file, opens a scratch buffer. The window closes when the
    editor exits (:q).

OPTIONS:
    --editor <path>   Editor binary to run (default: $VH_EDITOR, then
                      nvim, then vim found on PATH).
    --font-size <pt>  Terminal font size in points (default: 13).
    -h, --help        Show this help.
    -v, --version     Show version.

ENVIRONMENT:
    VH_EDITOR         Default editor binary path.

EXAMPLES:
    vh notes.md
    vh src/main.swift README.md
    vh --font-size 15 ~/.zshrc
"""

/// Parse the argument list (excluding argv[0]).
func parseArguments(_ args: [String]) -> ParseResult {
    var files: [String] = []
    var editorOverride: String?
    var fontSize: CGFloat = 13
    var passthrough = false

    var i = 0
    while i < args.count {
        let arg = args[i]
        if passthrough {
            files.append(arg)
            i += 1
            continue
        }
        switch arg {
        case "-h", "--help":
            return .help
        case "-v", "--version":
            return .version
        case "--":
            passthrough = true
        case "--editor":
            guard i + 1 < args.count else { return .failure("--editor requires a path") }
            editorOverride = args[i + 1]
            i += 1
        case "--font-size":
            guard i + 1 < args.count, let value = Double(args[i + 1]) else {
                return .failure("--font-size requires a number")
            }
            fontSize = CGFloat(value)
            i += 1
        default:
            if arg.hasPrefix("--editor=") {
                editorOverride = String(arg.dropFirst("--editor=".count))
            } else if arg.hasPrefix("--font-size=") {
                guard let value = Double(arg.dropFirst("--font-size=".count)) else {
                    return .failure("--font-size requires a number")
                }
                fontSize = CGFloat(value)
            } else if arg.hasPrefix("-") && arg != "-" {
                return .failure("unknown option: \(arg)")
            } else {
                files.append(arg)
            }
        }
        i += 1
    }

    guard let editor = resolveEditor(override: editorOverride) else {
        return .failure("no editor found — install nvim or vim, or pass --editor <path>")
    }

    return .run(LaunchConfig(editor: editor, files: files, fontSize: fontSize))
}

/// Resolve the editor binary: explicit override, then $VH_EDITOR, then nvim/vim on a
/// sensible search path. Shell aliases (e.g. vim→nvim) don't apply to spawned processes,
/// so we resolve to a real executable here.
func resolveEditor(override: String?) -> String? {
    let fm = FileManager.default

    func executable(at path: String) -> String? {
        fm.isExecutableFile(atPath: path) ? path : nil
    }

    if let override {
        // Accept either an absolute/relative path or a bare command name to look up.
        if override.contains("/") { return executable(at: override) }
        return lookup(command: override)
    }

    if let fromEnv = ProcessInfo.processInfo.environment["VH_EDITOR"], !fromEnv.isEmpty {
        if fromEnv.contains("/") { return executable(at: fromEnv) }
        if let resolved = lookup(command: fromEnv) { return resolved }
    }

    return lookup(command: "nvim") ?? lookup(command: "vim")
}

private func lookup(command: String) -> String? {
    let fm = FileManager.default
    var dirs = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"]
    if let path = ProcessInfo.processInfo.environment["PATH"] {
        dirs = path.split(separator: ":").map(String.init) + dirs
    }
    for dir in dirs {
        let candidate = (dir as NSString).appendingPathComponent(command)
        if fm.isExecutableFile(atPath: candidate) { return candidate }
    }
    return nil
}
