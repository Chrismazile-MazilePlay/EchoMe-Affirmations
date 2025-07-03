//
//  SpeechManager.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 6/30/25.
//

import AVFoundation
import SwiftUI
import Observation
import FirebaseFirestore
import FirebaseAuth

@MainActor
@Observable
class SpeechManager: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    var isSpeaking = false
    var currentUtteranceId: String?
    var currentVoice: VoiceProfile?
    
    // Completion handler for continuous play
    private var completionHandler: (() -> Void)?
    
    public override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.allowBluetooth, .allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func speak(_ text: String, voice: VoiceProfile = .defaultVoiceProfile) {
        // Stop current speech if any
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = voice.rate
        utterance.pitchMultiplier = voice.pitch
        utterance.volume = voice.volume
        
        // Set voice
        if let voiceIdentifier = voice.identifier,
           let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        currentUtteranceId = voice.identifier
        currentVoice = voice
        synthesizer.speak(utterance)
    }
    
    func speakForContinuousPlay(_ text: String, completion: (() -> Void)? = nil) {
        // Store completion handler
        self.completionHandler = completion
        
        // Use the current voice profile or default
        let voice = self.currentVoice ?? VoiceProfile.defaultVoiceProfile
        
        // Configure for background playback
        configureForBackgroundPlayback()
        
        // Speak with completion handling
        speak(text, voice: voice)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        completionHandler = nil
    }
    
    func pause() {
        synthesizer.pauseSpeaking(at: .immediate)
    }
    
    func resume() {
        synthesizer.continueSpeaking()
    }
    
    // MARK: - Background Audio Support
    
    private func configureForBackgroundPlayback() {
        do {
            // Configure audio session for background playback
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.allowBluetooth, .allowAirPlay, .mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure background audio: \(error)")
        }
    }
    
    // MARK: - Volume Control
    
    func setVolume(_ volume: Float) {
        // This would be used for mixing with background audio
        // For now, we'll use it to adjust the speech volume
        synthesizer.stopSpeaking(at: .word)
        
        if let currentVoice = currentVoice {
            var adjustedVoice = currentVoice
            adjustedVoice.volume = volume
            self.currentVoice = adjustedVoice
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.currentUtteranceId = nil
            
            // Call completion handler if set (for continuous play)
            if let completion = self.completionHandler {
                self.completionHandler = nil
                completion()
            }
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.currentUtteranceId = nil
            self.completionHandler = nil
        }
    }
}

// MARK: - Singleton for compatibility
extension SpeechManager {
    static let shared = SpeechManager()
}
