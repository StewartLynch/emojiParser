//
//  File.swift
//  
//
//  Created by Stewart Lynch on 2022-03-14.
//
import Foundation

class ParsingManager  {
    
    enum EmojiError: Error, LocalizedError {
        case invalidURL
        case invalidResponseStatus
        case dataTaskError(String)
        case corruptData
        case customError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return NSLocalizedString("The endpoint URL is invalid", comment: "")
            case .invalidResponseStatus:
                return NSLocalizedString("The API failed to issue a valid response.", comment: "")
            case .dataTaskError(let string):
                return string
            case .corruptData:
                return NSLocalizedString("The data provided appears to be corrupt", comment: "")
            case .customError(let string):
                return string
            }
        }
    }
        
    let version: String
    let urlString: String
    init(version: String) {
        self.version = version
        self.urlString = "https://unicode.org/Public/emoji/\(version)/emoji-test.txt"
        print(self.urlString)
    }
    
     func getEmojiText() async throws -> String {
         guard let url = URL(string: urlString) else { throw EmojiError.invalidURL }
         let (_, response) = try await URLSession.shared.data(from: url)
         guard
             let httpResponse = response as? HTTPURLResponse
         else {
             throw EmojiError.invalidResponseStatus
         }
         if httpResponse.statusCode == 404 {
             throw EmojiError.customError("Version \(version) does not appear to be a valid version.  Please double check 'https://unicode.org/Public/emoji/'. This tool is valid for versions 4.0 and higher.")
         }
         if httpResponse.statusCode == 200 {
             do {
                 return try String(contentsOf: url)
             } catch {
                 throw EmojiError.customError("Could not get contents of url")
             }
         } else {
             throw EmojiError.invalidResponseStatus
         }
    }
    
    func parseLines(for text: String) throws -> [Emoji] {
        var emojis = [Emoji]()
        var currentGroup = ""
        var currentSubGroup = ""
        let allLines = text.components(separatedBy: "\n")
        for line in allLines {
            if line.starts(with: "# group:") {
                currentGroup = line.replacingOccurrences(of: "# group: ", with: "")
            }
            if line.starts(with: "# subgroup:") {
                currentSubGroup = line.replacingOccurrences(of: "# subgroup: ", with: "")
            }
            if line.contains("fully-qualified     #") {
                let code = line.components(separatedBy: ";")[0].trimmingCharacters(in: .whitespaces)
                let other = line.components(separatedBy: ";")[1].components(separatedBy: "# ")[1]
                let char = other.components(separatedBy: " ")[0]
                let nameComponents = other.components(separatedBy: " ")
                var nameArray = [String]()
                for i in 2...nameComponents.count-1 {
                    nameArray.append(nameComponents[i])
                }
                let name = nameArray.joined(separator: " ")
                emojis.append(Emoji(codes: code, char: char, name: name, group: currentGroup, subgroup: currentSubGroup, category: "\(currentGroup) (\(currentSubGroup))"))
            }
        }
        return emojis
    }
    
    var emojiManager: String {
        """
//
//  EmojiManager.swift
//
//
//  Created by Stewart Lynch on 2022-03-14.
//  Based on gist from Jordi Bruin https://gist.github.com/jordibruin/4c230f0e643d7cd59bbda653406ba3e9
//

import Foundation

// Make sure that this file along with the emoji.json files are added to your project target
// To generate an array of EmojiObject all you need to do is to create an instance of
// Emoji manager and this will contain an array of emojis as the emoji property


class EmojiManager: ObservableObject {
    @Published var emojis: [EmojiObject] = []
    init() {
        decodeJSON()
    }
    func decodeJSON() {
        if let url = Bundle.main.url(forResource: "emoji", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let emoji: [EmojiObject] = try! JSONDecoder().decode([EmojiObject].self, from: data)
                self.emojis = emoji
            } catch {
                print("error:\\(error)")
            }
        }
    }
}

struct EmojiObject: Decodable, Hashable, Identifiable {
    let codes, char, name, category: String
    let subgroup: String

    let group: EmojiGroup
    var id: String { codes }
}

enum EmojiGroup: String, CaseIterable, Codable, Identifiable {
    case smileys = "Smileys & Emotion"
    case people = "People & Body"
    case animals = "Animals & Nature"
    case foodAndDrink = "Food & Drink"
    case travel = "Travel & Places"
    case activities = "Activities"
    case objects = "Objects"
    case symbols = "Symbols"
    case flags = "Flags"

    var id: String { rawValue }
}
"""
    }
var sampleView: String {
        """
//
//  EmojiPickerView.swift
//  Emoji Sample Picker
//
//  Created by Stewart Lynch on 2022-03-15.
//

import SwiftUI

struct EmojiPickerView: View {
    @StateObject var emojiManager = EmojiManager()
    @State private var selectedGroup: EmojiGroup = .objects
    @State private var selectedEmoji: EmojiObject?
    private let columns:[GridItem] = [GridItem(.flexible()), GridItem(.flexible()),GridItem(.flexible()),GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        VStack {
            Picker("Grooup", selection: $selectedGroup) {
                ForEach(EmojiGroup.allCases) { group in
                    Text(group.rawValue).tag(group)
                }
            }
            Text(selectedEmoji?.name ?? "Tap on Emoji to select it.")
                .font(.title2)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(emojiManager.emojis.filter{$0.group == selectedGroup}) { emoji in
                        Text(emoji.char)
                            .font(.largeTitle)
                            .onTapGesture {
                                selectedEmoji = emoji
                            }
                            .padding()
                            .border(selectedEmoji == emoji ? Color.green : Color.clear)
                    }
                }
            }
        }
        .onChange(of: selectedGroup) { _ in
            selectedEmoji = nil
        }
    }
}

struct EmojiPickerView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiPickerView()
    }
}
"""
    }
}
