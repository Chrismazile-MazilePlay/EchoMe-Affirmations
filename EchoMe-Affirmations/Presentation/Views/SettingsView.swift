//
//  SettingsView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Voice") {
                    NavigationLink {
                        Text("Voice Settings")
                    } label: {
                        Label("Voice Settings", systemImage: "speaker.wave.2")
                    }
                }
                
                Section("Preferences") {
                    NavigationLink {
                        Text("Categories")
                    } label: {
                        Label("Categories", systemImage: "square.grid.2x2")
                    }
                    
                    NavigationLink {
                        Text("Continuous Play")
                    } label: {
                        Label("Continuous Play", systemImage: "play.circle")
                    }
                }
                
                Section("About") {
                    NavigationLink {
                        Text("About EchoMe")
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
