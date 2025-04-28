//
//  CreateThreadView.swift
//  WebexConnectDemo
//

import SwiftUI

/// A view for creating a new thread in the application. This view allows users to input a thread title and create a new thread.
struct CreateThreadView: View {
    @State private var threadTitle: String = ""
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: ThreadsViewModel
    @Binding var activeThreadId: String?
    var onThreadCreated: ((String, String) -> Void)?  // Add the callback

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(AppFonts.sfProMedium14)
                        .foregroundColor(AppColors.signoutRed)
                }

                Spacer()

                Text("Create a thread")
                    .font(AppFonts.sfProRegular22)
                    .foregroundColor(AppColors.whiteOpacity95)

                Spacer()

                Button(action: { createThread() }) {
                    Text("Create")
                        .font(AppFonts.sfProMedium14)
                        .foregroundColor(threadTitle.isEmpty ? .gray : AppColors.whiteOpacity95)
                }
                .disabled(threadTitle.isEmpty)
            }
            .padding(.horizontal)
            .padding(.top)

            Text("Start a conversation.")
                .font(AppFonts.sfProRegular14)
                .foregroundColor(AppColors.whiteOpacity95)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            // Reusable InputFieldView
            InputFieldView(text: $threadTitle, placeholder: "Thread title (required)")
            .padding(.horizontal, 10)

            Spacer()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
    }

    private func createThread() {
        viewModel.createThread(with: threadTitle) { createdThreadId, title in
            activeThreadId = createdThreadId
            onThreadCreated?(createdThreadId, title)  // Trigger callback after success
            dismiss()  // Dismiss only after thread is successfully created
        }
    } 
}


#Preview {
    CreateThreadView(
        viewModel: ThreadsViewModel(), // Replace with a mocked or default instance
        activeThreadId: .constant(nil) // Use a constant binding for preview purposes
    )
}

