import SwiftUI

struct ComposeView: View {
    @EnvironmentObject var accountViewModel: AccountViewModel
    @EnvironmentObject var inboxViewModel: InboxViewModel
    @StateObject private var viewModel = ComposeViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showDiscardAlert = false

    var replyTo: EmailMessage?
    var forwardMessage: EmailMessage?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.surfaceBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // To Field
                        composeField(label: "To", text: $viewModel.toField)

                        Divider().padding(.leading, 60)

                        // CC/BCC Toggle
                        if !viewModel.showCCBCC {
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    viewModel.showCCBCC = true
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("Cc/Bcc")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(AppTheme.Colors.primary)
                                    Spacer()
                                }
                                .padding(.vertical, AppTheme.Spacing.sm)
                            }

                            Divider().padding(.leading, 60)
                        }

                        // CC/BCC Fields
                        if viewModel.showCCBCC {
                            composeField(label: "Cc", text: $viewModel.ccField)
                            Divider().padding(.leading, 60)
                            composeField(label: "Bcc", text: $viewModel.bccField)
                            Divider().padding(.leading, 60)
                        }

                        // Subject
                        composeField(label: "Subject", text: $viewModel.subjectField)

                        Divider()

                        // Body
                        TextEditor(text: $viewModel.bodyField)
                            .font(AppTheme.Typography.body)
                            .frame(minHeight: 300)
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.top, AppTheme.Spacing.sm)
                            .scrollContentBackground(.hidden)
                    }
                    .background(AppTheme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                    .padding(AppTheme.Spacing.lg)
                }
            }
            .navigationTitle(replyTo != nil ? "Reply" : forwardMessage != nil ? "Forward" : "New Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if viewModel.hasContent {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.send()
                            if viewModel.sendSuccess {
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSending {
                            ProgressView()
                                .tint(.white)
                                .frame(width: 28, height: 28)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 18))
                        }
                    }
                    .disabled(!viewModel.canSend || viewModel.isSending)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        viewModel.canSend && !viewModel.isSending
                            ? AppTheme.Colors.accentGradient
                            : LinearGradient(colors: [.gray.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                    .foregroundStyle(.white)
                }
            }
            .alert("Discard Draft?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("Your draft will be lost.")
            }
            .alert("Send Failed", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear {
                if let account = accountViewModel.currentAccount {
                    viewModel.configure(with: account)
                }
                if let replyTo = replyTo {
                    viewModel.setupReply(to: replyTo)
                } else if let forward = forwardMessage {
                    viewModel.setupForward(forward)
                }
            }
        }
    }

    private func composeField(label: String, text: Binding<String>) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text(label)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.textTertiary)
                .frame(width: 50, alignment: .trailing)

            TextField("", text: text)
                .font(AppTheme.Typography.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(label == "Subject" ? .default : .emailAddress)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.md)
    }
}
