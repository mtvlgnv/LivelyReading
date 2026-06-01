import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await signIn() }
                    } label: {
                        HStack {
                            if isWorking { ProgressView().padding(.trailing, 6) }
                            Text("Sign in")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSubmit || isWorking)
                }

                if Config.enableAppleSignIn {
                    Section {
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            handleApple(result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 46)
                    }
                }

                Section {
                    Button("Continue without an account") { dismiss() }
                    Text("Fast mode works free and offline-friendly. An account adds Balanced/Deep modes and word-bank sync.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Sign in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var canSubmit: Bool {
        email.contains("@") && password.count >= 1
    }

    private func signIn() async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await app.signIn(email: email.trimmingCharacters(in: .whitespaces),
                                  password: password)
            dismiss()
        } catch let error as APIError {
            errorMessage = error.message
        } catch {
            errorMessage = "Couldn't sign in. Please try again."
        }
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8)
            else {
                errorMessage = "Apple didn't return a valid token."
                return
            }
            let name = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            Task {
                isWorking = true
                errorMessage = nil
                defer { isWorking = false }
                do {
                    try await app.signInWithApple(idToken: idToken,
                                                  name: name.isEmpty ? nil : name)
                    dismiss()
                } catch let error as APIError {
                    errorMessage = error.message
                } catch {
                    errorMessage = "Couldn't sign in with Apple."
                }
            }
        case .failure:
            // User canceled or the system errored — no message needed for cancel.
            break
        }
    }
}
