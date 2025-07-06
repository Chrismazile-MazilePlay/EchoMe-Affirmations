//
//  TextFieldStyles.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/6/25.
//

import SwiftUI

// MARK: - Rounded TextField Style
struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
}

// MARK: - ViewModifier Alternative
struct RoundedTextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
}

extension View {
    func roundedTextFieldStyle() -> some View {
        modifier(RoundedTextFieldModifier())
    }
}
