//
//  ErrorHandler.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/3/25.
//

import SwiftUI

// MARK: - Error Alert Modifier
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: AppError?
    let retryAction: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: .constant(error != nil),
                presenting: error
            ) { _ in
                if let retryAction = retryAction {
                    Button("Retry", action: retryAction)
                    Button("Cancel", role: .cancel) {
                        error = nil
                    }
                } else {
                    Button("OK") {
                        error = nil
                    }
                }
            } message: { error in
                Text(error.localizedDescription)
            }
    }
}

// MARK: - Toast Error Modifier
struct ToastErrorModifier: ViewModifier {
    @Binding var error: AppError?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                if let error = error {
                    GlassCard(
                        padding: 16,
                        cornerRadius: 12,
                        material: .thick
                    ) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            
                            Text(error.localizedDescription)
                                .font(.callout)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    self.error = nil
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                self.error = nil
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .animation(.spring(), value: error != nil)
        }
    }
}

// MARK: - View Extension
extension View {
    func errorAlert(error: Binding<AppError?>, retry: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlertModifier(error: error, retryAction: retry))
    }
    
    func errorToast(error: Binding<AppError?>) -> some View {
        modifier(ToastErrorModifier(error: error))
    }
}

// MARK: - Error Handler Protocol
protocol ErrorHandling: AnyObject {
    var error: AppError? { get set }
    func handleError(_ error: Error)
}

extension ErrorHandling {
    func handleError(_ error: Error) {
        Logger.error("Error occurred: \(error)")
        
        if let appError = error as? AppError {
            self.error = appError
        } else if let firebaseError = error as? FirebaseError {
            switch firebaseError {
            case .notConfigured:
                self.error = .custom("App not properly configured")
            case .invalidData:
                self.error = .dataNotFound
            case .unknown(let underlyingError):
                self.error = .unknown(underlyingError)
            }
        } else {
            self.error = .unknown(error)
        }
    }
}
