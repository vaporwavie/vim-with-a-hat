import AppKit

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
