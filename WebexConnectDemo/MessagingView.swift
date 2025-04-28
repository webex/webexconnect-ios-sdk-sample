//
//  MessagingView.swift
//  WebexConnectDemo
//

import SwiftUI
import WebexConnectInAppMessaging
import WebexConnectCore

/// `MessagingView` displays the main messaging interface for the user.
///
/// It provides the following functionalities:
/// - Shows the user's profile picture and connection status.
/// - Displays a list of conversation threads fetched from the server.
/// - Allows the user to create new conversation threads.
/// - Navigates to the selected conversation's detail view.
/// - Handles user session state and redirects to login when signed out.
struct MessagingView: View {
    @Binding var isUserSignedIn: Bool
    let userId: String
    @Binding var selectedTab: Int
    @ObservedObject var viewModel: ThreadsViewModel
    
    @State private var isShowingProfile = false
    @State private var showLoginView = false
    @State private var isCreateThreadViewPresented = false
    @State private var navigateToThread = false
    @State private var activeThreadId: String? = nil
    @State private var activeThreadTitle: String? = nil
    
    @State private var connectionText = "Connected"
    @State private var connectionColor = AppColors.connectionColor
    @State private var connectionBackgroundColor = AppColors.connectionBackgroundColor
    @State private var profileAvatarColor = AppColors.profileAvatarColor

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                profileRow
                messagingTitleRow
                threadsList
                
                NavigationLink(
                    destination: getDestinationView(),
                    isActive: $navigateToThread
                ) {
                    EmptyView() // Invisible trigger
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .foregroundColor(.white)
            .sheet(isPresented: $isShowingProfile) {
                ProfileView(userId: userId, sdkVersion: WebexConnectProvider.instance.sdkVersion, onDismiss: { isShowingProfile = false }, isUserSignedIn: $isUserSignedIn, selectedTab: $selectedTab)
            }
            .sheet(isPresented: $isCreateThreadViewPresented) {
                CreateThreadView(viewModel: viewModel, activeThreadId: $activeThreadId) { threadId, threadTitle in
                    activeThreadId = threadId
                    activeThreadTitle = threadTitle
                    navigateToThread = true // Trigger navigation
                }
            }
            .onAppear{
                // Load threads on appear
                viewModel.loadConversarionsWith(type: .conversation)
            }
            .onReceive(viewModel.$connectionStatus) { status in
                switch status {
                case .connected:
                    connectionText = "Connected"
                    connectionColor = AppColors.connectionColor
                    connectionBackgroundColor = AppColors.connectedBackgroundColor
                    profileAvatarColor = Color(red: 39 / 255, green: 161 / 255, blue: 122 / 255, opacity: 1.0)
                case .connecting:
                    connectionText = "Reconnecting"
                    connectionColor = AppColors.connectingColor
                    connectionBackgroundColor = AppColors.connectingBackgroundColor
                    profileAvatarColor = connectionColor
                default :
                    connectionText = "Disconnected"
                    connectionColor = AppColors.connectingColor
                    connectionBackgroundColor = AppColors.disconnectedBackgroundColor
                    profileAvatarColor = connectionColor
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Alert"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
            .onChange(of: isUserSignedIn) { newValue in
                if !newValue {
                    showLoginView = true
                }
            }
        }
        .fullScreenCover(isPresented: $showLoginView) {
            LoginView()
        }
    }
    
    private func getLastMessageFor(thread: InAppThread) -> InAppMessage {
        let defaultMessage = InAppMessage()
        defaultMessage.thread = thread
        let lastMessage = viewModel.messages.first(where: { $0.thread?.id == thread.id }) ?? defaultMessage
        return lastMessage
    }
}

// MARK: - UI Components
private extension MessagingView {
    var profileRow: some View {
        HStack {
            Button(action: { isShowingProfile = true }) {
                Image("Avatar")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .foregroundColor(profileAvatarColor)
                            .frame(width: 12, height: 12)
                            .offset(x: 15, y: 15)
                    )
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Button(action: { isCreateThreadViewPresented = true }) {
                Image("button-add")
                    .resizable()
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
        .padding(.top)
    }

    var messagingTitleRow: some View {
        HStack {
            Text("Messaging")
                .font(AppFonts.sfProDisplayBold34)
                .foregroundColor(AppColors.whiteOpacity95)

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .foregroundColor(connectionColor)
                    .frame(width: 12, height: 12)

                Text(connectionText)
                    .font(AppFonts.sfProMedium14)
                    .multilineTextAlignment(.leading) // Left alignment
                    .foregroundColor(connectionColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(connectionBackgroundColor)
            .cornerRadius(4)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    var threadsList: some View {
        Group {
            if viewModel.threads.isEmpty {
                Text("No threads available.")
                    .foregroundColor(.gray)
                    .padding()
                
                Spacer()
            } else {
                List(viewModel.threads, id: \.id) { thread in
                    NavigationLink(
                        destination: ConversationView(selectedThread: thread, conversationViewModel: getConversationViewModel())
                    ) {
                        ThreadRowView(thread: thread, lastMessage: getLastMessageFor(thread: thread))
                    }
                    .listRowBackground(Color.black)
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

// MARK: - Helper Functions
private extension MessagingView {
    func getDestinationView() -> some View {
        if let thread = viewModel.tempThread {
            return AnyView(
                ConversationView(selectedThread: thread, conversationViewModel: getConversationViewModel())
            )
        } else {
            return AnyView(EmptyView()) // Provide a fallback
        }
    }
    
    private func getConversationViewModel() -> ConversationViewModel {
        let conversationViewModel = ConversationViewModel()
        conversationViewModel.connectionStatus = viewModel.connectionStatus
        return conversationViewModel
    }
}

// MARK: - Thread Row View
/// `ThreadRowView` represents a single conversation thread row in the messaging list.
///
/// It shows:
/// - The thread's title with a fallback if the title is missing.
/// - The last message preview for the thread.
/// - The timestamp of the last update.
/// - A circular avatar generated from the thread's initials.
struct ThreadRowView: View {
    let thread: InAppThread  // Replace with the actual model type
    let lastMessage: InAppMessage

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.8))
                    .frame(width: 40, height: 40)

                Text(getInitials(from: thread.title ?? "Unknown"))
                    .font(AppFonts.sfProRegular22)
                    .foregroundColor(AppColors.whiteOpacity95)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack() {
                    Text(thread.title ?? "Unknown")
                        .font(AppFonts.sfProRegular17)
                        .foregroundColor(AppColors.whiteOpacity95)
                        .lineLimit(1) // Ensure the title stays on one line
                        .truncationMode(.tail)

                    Spacer()

                    if let updatedAt = thread.updatedAt {
                        Text(formatDate(updatedAt))
                            .font(AppFonts.sfProRegular13)
                            .foregroundColor(AppColors.whiteOpacity60)
                    }
                }

                Text(lastMessage.message ?? "")
                    .font(AppFonts.sfProRegular15)
                    .foregroundColor(AppColors.whiteOpacity70)
                    .lineLimit(1) // Ensure the title stays on one line
                    .truncationMode(.tail)
            }

            Spacer()
        }
        .padding(.vertical, 0)
    }

    private func getInitials(from title: String) -> String {
        let words = title.split(separator: " ")
        let firstLetter = words.first?.prefix(1) ?? ""
        let secondLetter = words.dropFirst().first?.prefix(1) ?? ""
        return "\(firstLetter)\(secondLetter)".uppercased()
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
}

struct MessagingView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State var isConnected = true
        @State var isUserSignedIn = true

        var body: some View {
            MessagingView(
                isUserSignedIn: $isUserSignedIn,
                userId: "1234",
                selectedTab: .constant(0), viewModel: ThreadsViewModel()
            )
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
