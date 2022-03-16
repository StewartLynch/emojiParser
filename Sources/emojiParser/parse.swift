import ArgumentParser

import Foundation

protocol AsyncParsableCommand: ParsableCommand {
    mutating func runAsync() async throws
}

extension ParsableCommand {
    static func main() async {
        do {
            var command = try parseAsRoot(nil)
            if var asyncCommand = command as? AsyncParsableCommand {
                try await asyncCommand.runAsync()
            } else {
                try command.run()
            }
        } catch {
            exit(withError: error)
        }
    }
}

@main
enum Parse {
    static func main() async {
        await EmojiParser.main()
    }
}

struct EmojiParser: ParsableCommand, AsyncParsableCommand {
    @Option(name: .long, help: "The version to parse") var ver : String
    @Flag(name: .shortAndLong, help: "Include EmojiManager class") var managerIncluded = false
    @Flag(name: .shortAndLong, help: "Include Sample Picker View") var sampleView = false


    mutating func runAsync() async throws {
        await asyncParse(version: ver, managerIncluded: managerIncluded)
    }

    func asyncParse(version: String, managerIncluded: Bool) async {
        let parser = ParsingManager(version: version)
        var jsonString = ""
        print("Fetching and parsing.....")
        do {
            let text = try await parser.getEmojiText()
            let emojis = try parser.parseLines(for: text)
            let encoder = JSONEncoder()
            let json = try? encoder.encode(emojis)
            if let json = json {
                jsonString = String(data: json, encoding: .utf8) ?? "Not valid json"
            }
            guard let _ = try? jsonString.write(toFile: "emoji.json", atomically: true, encoding: .utf8) else {
                print("Couldn't write to file 'emoji.json'")
                return
            }
            print("Generated json file")
            if managerIncluded {
                guard let _ = try? parser.emojiManager.write(toFile: "EmojiManager.swift", atomically: true, encoding: .utf8) else {
                    print("Couldn't write to file 'EmojiManager.swift'")
                    return
                }
                print("Generated Sample EmojiManager")
            }
            if sampleView {
                guard let _ = try? parser.sampleView.write(toFile: "EmojiPickerView.swift", atomically: true, encoding: .utf8) else {
                    print("Couldn't write to file 'EmojiPickerView.swift'")
                    return
                }
                print("Generated Sample EmojiPickerView")
            }
            print("Done!")
            
        } catch {
            print(error.localizedDescription)
        }
    }
}
