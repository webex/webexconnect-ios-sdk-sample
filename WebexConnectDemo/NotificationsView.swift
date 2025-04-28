import SwiftUI
import WebexConnectInAppMessaging
import WebexConnectCore

/// A view that displays a list of notification threads and their latest messages.
///
/// `NotificationsView` is the main screen for presenting a user's Announcement threads.
/// It shows the profile avatar, a connection status indicator, and a list of threads.
/// Tapping on a thread navigates the user to a `ConversationView`.
///
/// This view handles:
/// - Showing a profile sheet
/// - Displaying connection status
/// - Navigating to individual thread conversations
/// - Fetching Announcement threads from the `ThreadsViewModel`
struct NotificationsView: View {
    @State private var showAlert: Bool = false // For handling alert (optional)
    @EnvironmentObject var viewModel: ThreadsViewModel
    @State private var selectedThread: InAppThread? // Selected thread for navigation

    @State private var navigateToConversationView: Bool = false // Navigation trigger
    @State private var isShowingProfile = false

    @Binding var isUserSignedIn: Bool
    let userId: String
    @Binding var selectedTab: Int
    
    @State private var connectionText = "Connected"
    @State private var connectionColor = AppColors.connectionColor
    @State private var connectionBackgroundColor = AppColors.connectionBackgroundColor
    @State private var profileAvatarColor = AppColors.profileAvatarColor

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Profile Picture
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
                }
                .padding(.horizontal)
                .padding(.top)
                // Header Section
                notificationsTitleRow
                .padding(.horizontal)
                .padding(.top)
                
                // Threads List
                if viewModel.threads.isEmpty {
                    Text("No threads available.")
                        .foregroundColor(.gray)
                        .padding()
                    
                    Spacer()
                } else {
                    // Notifications List
                    List {
                        ForEach(viewModel.threads, id: \.id) { thread in
                            let lastMessage = getLastMessageFor(thread: thread)
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(thread.title ?? "No Title")
                                        .font(AppFonts.sfProRegular17)
                                        .foregroundColor(AppColors.whiteOpacity95)
                                        .lineLimit(1) // Ensure the title stays on one line
                                        .truncationMode(.tail)
                                    Text(lastMessage.message ?? "")
                                        .font(AppFonts.sfProRegular15)
                                        .foregroundColor(AppColors.whiteOpacity70)
                                        .lineLimit(1) // Ensure the title stays on one line
                                        .truncationMode(.tail)
                                }
                                
                                Spacer()

                                                            // Detail disclosure indicator
                                                            Image(systemName: "chevron.right")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 12, height: 12)
                                    .foregroundColor(AppColors.whiteOpacity70)
                            }
                            .padding(.vertical, 0)
                            .onTapGesture {
                                                            selectedThread = thread // Store the selected thread
                                                            navigateToConversationView = true // Trigger navigation
                                                        }
                        }
                        .listRowBackground(Color.black) // Match the background color
                    }
                    .listStyle(PlainListStyle()) // Remove extra styling

                }

            }
            .background(Color.black.edgesIgnoringSafeArea(.all)) // Match the theme
            .sheet(isPresented: $isShowingProfile) {
                ProfileView(userId: userId, sdkVersion: WebexConnectProvider.instance.sdkVersion, onDismiss: { isShowingProfile = false }, isUserSignedIn: $isUserSignedIn, selectedTab: $selectedTab)
            }
            .onAppear {
                // Load threads on appear
                viewModel.loadConversarionsWith(type: .announcement)
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
            // Navigation to MessageListView
            .navigationDestination(isPresented: $navigateToConversationView) {
                if let thread = selectedThread {
                    ConversationView(selectedThread: thread, conversationViewModel: getConversationViewModel())
                }
            }
        }
    }
    
    private func getConversationViewModel() -> ConversationViewModel {
        let conversationViewModel = ConversationViewModel()
        conversationViewModel.connectionStatus = viewModel.connectionStatus
        return conversationViewModel
    }
    
    private var notificationsTitleRow: some View {
        HStack {
            Text("Notifications")
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
    
    private func getLastMessageFor(thread: InAppThread) -> InAppMessage {
        let defaultMessage = InAppMessage()
        defaultMessage.thread = thread
        let lastMessage = viewModel.messages.first(where: { $0.thread?.id == thread.id }) ?? defaultMessage
        return lastMessage
    }
}

struct NotificationsView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State var isConnected = true
        @State var isUserSignedIn = true

        var body: some View {
            NotificationsView(
                isUserSignedIn: $isUserSignedIn,
                userId: "1234",
                selectedTab: .constant(0)
            )
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
