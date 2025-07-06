//
//  generate_links.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/6/25.
//

import Foundation

// --- Configuration ---
let baseURL = "https://raw.githubusercontent.com/Chrismazile-MazilePlay/EchoMe-Affirmations/main/"
let projectRootPath = "."
let outputFileName = "RawFilesLink.txt"
let chunkSize = 15

// Directories to completely skip
let excludedDirectoryNames: Set<String> = [
    ".git",
    ".build",
    "Pods",
    "SourcePackages",
    "DerivedData",
    ".swiftpm"
]
// Specific files to ignore by name
let excludedFileNames: Set<String> = [
    ".DS_Store",
    "generate_links.swift" // Exclude the script itself
]


// --- Main Logic ---
let fileManager = FileManager.default
let rootURL = URL(fileURLWithPath: projectRootPath)
var fileURLs: [String] = []

print("🔎 Starting recursive file scan...")

guard let enumerator = fileManager.enumerator(
    at: rootURL,
    includingPropertiesForKeys: [.isRegularFileKey],
    options: [.skipsHiddenFiles]
) else {
    fatalError("Failed to create file enumerator.")
}

for case let fileURL as URL in enumerator {
    // Check if the file is inside a directory that should be skipped entirely
    let components = fileURL.pathComponents
    if components.contains(where: { excludedDirectoryNames.contains($0) }) {
        enumerator.skipDescendants()
        continue
    }

    // Check if the file itself should be skipped by name
    if excludedFileNames.contains(fileURL.lastPathComponent) {
        continue
    }

    // Ensure we only process files, not directories
    do {
        let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
        if resourceValues.isRegularFile == true {
            // Construct the relative path for the URL
            guard var relativePath = fileURL.path.replacingOccurrences(
                of: rootURL.path, with: ""
            ).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                continue
            }

            if relativePath.hasPrefix("/") {
                relativePath.removeFirst()
            }

            let fullRawURL = baseURL + relativePath
            fileURLs.append(fullRawURL)
        }
    } catch {
        // Ignore files we can't read
    }
}

print("✅ Found \(fileURLs.count) files.")

// --- Generate Plain Text Output in Chunks ---
var outputText = ""
for (index, url) in fileURLs.enumerated() {
    outputText.append(url + "\n")
    
    // Check if it's time to add a blank line separator
    if (index + 1) % chunkSize == 0 && index + 1 != fileURLs.count {
        outputText.append("\n")
    }
}

// --- Write to File ---
do {
    let outputURL = URL(fileURLWithPath: outputFileName)
    try outputText.write(to: outputURL, atomically: true, encoding: .utf8)
    print("🚀 Successfully created \(outputFileName) with URLs split into chunks of \(chunkSize).")
} catch {
    print("❌ Error generating plain text file: \(error)")
}
