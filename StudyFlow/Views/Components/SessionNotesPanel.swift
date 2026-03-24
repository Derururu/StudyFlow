import SwiftUI

struct SessionNotesPanel: View {
    @Bindable var viewModel: TimerViewModel
    @State private var isPreviewMode: Bool = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.isNotesExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("SCRATCHPAD")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textMuted)
                        .tracking(1.5)
                    
                    Spacer()
                    
                    if !viewModel.sessionNotes.isEmpty && !viewModel.isNotesExpanded {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 6, height: 6)
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.textMuted)
                        .rotationEffect(.degrees(viewModel.isNotesExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Expanded content
            if viewModel.isNotesExpanded {
                VStack(spacing: 0) {
                    // Toolbar
                    HStack {
                        Spacer()
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPreviewMode.toggle()
                            }
                        } label: {
                            Image(systemName: isPreviewMode ? "pencil" : "eye")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(width: 28, height: 28)
                                .background(Theme.surfaceLight.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .help(isPreviewMode ? "Edit Notes" : "Preview Markdown")
                        
                        Button {
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(viewModel.sessionNotes, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(width: 28, height: 28)
                                .background(Theme.surfaceLight.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .help("Copy to Clipboard")
                        
                        Button {
                            withAnimation {
                                viewModel.sessionNotes = ""
                                isPreviewMode = false
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(width: 28, height: 28)
                                .background(Theme.surfaceLight.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .help("Clear Notes")
                        .disabled(viewModel.sessionNotes.isEmpty)
                        .opacity(viewModel.sessionNotes.isEmpty ? 0.4 : 1.0)
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    
                    // Text Editor or Preview
                    if isPreviewMode {
                        ScrollView {
                            VStack(alignment: .leading) {
                                if let attributedString = try? AttributedString(markdown: viewModel.sessionNotes, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                                    Text(attributedString)
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundStyle(Theme.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    Text(viewModel.sessionNotes)
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundStyle(Theme.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(12)
                        }
                        .frame(height: 120)
                    } else {
                        TextEditor(text: $viewModel.sessionNotes)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .frame(height: 120)
                            .focused($isFocused)
                            // Placeholder
                            .overlay(alignment: .topLeading) {
                                if viewModel.sessionNotes.isEmpty {
                                    Text("Jot something down...")
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundStyle(Theme.textMuted)
                                        .padding(.horizontal, 13)
                                        .padding(.vertical, 8)
                                        .allowsHitTesting(false)
                                }
                            }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusSm)
                        .fill(Theme.surface.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cornerRadiusSm)
                                .stroke(isFocused ? Theme.accent.opacity(0.5) : Theme.surfaceLight.opacity(0.5), lineWidth: 1)
                        )
                )
                .transition(.opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95)))
            }
        }
    }
}
