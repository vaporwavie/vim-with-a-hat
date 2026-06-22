import AppKit

// SwiftTerm draws glyphs through CoreGraphics, which honors the global
// `AppleFontSmoothing` default. Users who disable it system-wide (`defaults
// write -g AppleFontSmoothing 0`) get noticeably thinner text here than in
// terminals like Ghostty that force their own smoothing. Writing the key into
// this process's own defaults domain (higher precedence than the global one)
// before AppKit starts restores the heavier, consistent rendering.
UserDefaults.standard.set(1, forKey: "AppleFontSmoothing")

switch parseArguments(Array(CommandLine.arguments.dropFirst())) {
case .help:
    print(helpText)
    exit(0)

case .version:
    print("vim-with-a-hat \(hatVersion)")
    exit(0)

case .failure(let message):
    FileHandle.standardError.write(Data("vh: \(message)\n".utf8))
    exit(64) // EX_USAGE

case .run(let config):
    let app = NSApplication.shared
    let delegate = HatAppDelegate(config: config)
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    app.run()
}
