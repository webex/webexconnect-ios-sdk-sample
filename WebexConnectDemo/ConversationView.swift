//
//  ConversationView.swift
//  WebexConnectDemo
//

import SwiftUI
import WebexConnectInAppMessaging

struct HideTabBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            return content.toolbar(.hidden, for: .tabBar)
        } else {
            return content
        }
    }
}

/// A view that displays a conversation thread, allowing users to send and receive messages. This view includes a header with the thread title and connection status, a list of messages, and a composer for sending new messages. It also handles scrolling to the last message and displaying indicators for new messages.
struct ConversationView: View {
    let selectedThread: InAppThread
    @State private var messageText: String = ""
    @StateObject var conversationViewModel = ConversationViewModel()

    @Environment(\.presentationMode) private var presentationMode
    @State private var showNewMessageIndicator = false
    @State private var showScrollToBottomIndicator = false
    @State private var previousMessagesCount = 0
    @State private var scrollViewProxy: ScrollViewProxy?
    
    @State private var connectionText: String = "Connected"
    @State private var connectionColor: Color = AppColors.connectionColor
    @State private var connectionBackgroundColor: Color = AppColors.connectionBackgroundColor
    
    @State private var defaultY: CGFloat = 0
    @State private var lastItemOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerView
                
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        messagesList(proxy: proxy)

                        GeometryReader { geo in
                            Rectangle()
                                .frame(width: 0, height: 0)
                                .onAppear (perform: {
                                    defaultY = geo.frame(in: .global).minY
                                })
                                .onChange(of: geo.frame(in: .global).minY){ minY in
                                    handleScroll(minY)
                                }
                        }
                        .frame(width: 0, height: 0)
                    }
                    .frame(maxHeight: .infinity)
                    .onAppear {
                        self.scrollViewProxy = proxy // Store the proxy
                        conversationViewModel.sendReadReceipts()
                        if let threadID = selectedThread.id {
                            conversationViewModel.clearMessages()
                            conversationViewModel.threadId = threadID
                            conversationViewModel.loadAndFetchMessages(threadID: threadID)

                            if !conversationViewModel.messages.isEmpty {
                                scrollToLastMessage()
                            }
                        }
                    }
                    .onReceive(conversationViewModel.$connectionStatus) { status in
                        switch status {
                        case .connected:
                            connectionText = "Connected"
                            connectionColor = AppColors.connectionColor
                            connectionBackgroundColor = AppColors.connectedBackgroundColor
                        case .connecting:
                            connectionText = "Reconnecting"
                            connectionColor = AppColors.connectingColor
                            connectionBackgroundColor = AppColors.connectingBackgroundColor
                        default :
                            connectionText = "Disconnected"
                            connectionColor = AppColors.connectingColor
                            connectionBackgroundColor = AppColors.disconnectedBackgroundColor
                        }
                    }
                }
                
                if determineThreadType() != .announcement {
                    composerView
                        .background(Color.black) // Ensures layout stability
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
            .modifier(HideTabBarModifier())
            
            if (showNewMessageIndicator || showScrollToBottomIndicator), let proxyTest = self.scrollViewProxy {
                newMessageIndicator(proxy: proxyTest)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.leading, 16)
            
            
            Text(selectedThread.title ?? "")
                .font(AppFonts.sfProBold20)
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
        .padding(.vertical, 12)
        .background(Color.black)
    }
    
    // MARK: - Messages List
       private func messagesList(proxy: ScrollViewProxy) -> some View {
           LazyVStack(spacing: 0) {               ForEach(conversationViewModel.sortedGroupedMessages, id: \.key) { group in
                   Section(header: GroupHeaderView(title: group.key)) {
                       ForEach(group.value, id: \.transactionId) { message in
                           MessageRowView(message: message)
                               .id(message.transactionId)
                               .background(GeometryReader { geo in
                                                                       Color.clear
                                                                           .onAppear {
                                                                               updateLastItemOffset(geo: geo, message: message)
                                                                           }
                                                                   })                       }
                   }
               }
           }
           .padding(.top, 10)
           .background(Color.black.edgesIgnoringSafeArea(.all))
           .onChange(of: conversationViewModel.sortedGroupedMessages.flatMap { $0.value }.count) { newCount in
               handleNewMessages(proxy: proxy, newCount: newCount)
           }
       }
    
    // 🔹 Function to update offset dynamically
    private func updateLastItemOffset(geo: GeometryProxy, message: InAppMessage) {
        DispatchQueue.main.async {
            lastItemOffset = geo.frame(in: .global).minY
        }
    }
    
    private func handleScroll(_ offset: CGFloat) {
        let threshold: CGFloat = 80 // Adjust as needed
        if lastItemOffset != 0 && lastItemOffset + threshold < offset { // Scrolled up
            showScrollToBottomIndicator = true
        } else {
            showScrollToBottomIndicator = false
        }
    }
    
    private var composerView: some View {
        HStack {
            ZStack(alignment: .leading) {
                if messageText.isEmpty {
                    Text("Write a message")
                        .font(AppFonts.sfProRegular17)
                        .foregroundColor(AppColors.whiteOpacity95)
                        .padding(.leading, 15)
                }
                
                TextField("", text: $messageText)
                    .padding(.vertical, 10)
                    .padding(.leading, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.5))
                    )
                    .font(AppFonts.sfProRegular17)
                    .foregroundColor(AppColors.whiteOpacity95)
                    .textInputAutocapitalization(.sentences)
                    .keyboardType(.default)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.95), lineWidth: 1)
                    )
            }
            .overlay(
                HStack {
                    Spacer()
                    if !messageText.isEmpty {
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .padding(.trailing, 10)
                        }
                    }
                }
            )
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
        .background(Color.black)
    }
    
    // MARK: - Handling New Messages
    private func handleNewMessages(proxy: ScrollViewProxy, newCount: Int) {
            let wasAtBottom = !showScrollToBottomIndicator
            let isIncomingMessage = newCount > previousMessagesCount && (conversationViewModel.sortedGroupedMessages.flatMap { $0.value }.last?.isOutgoing == false)

            if wasAtBottom {
                scrollToLastMessage()
            } else if isIncomingMessage {
                showNewMessageIndicator = true
            }

            previousMessagesCount = newCount
        }
    
    /// Floating "New Messages" Button
    private func newMessageIndicator(proxy: ScrollViewProxy) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                HStack(spacing: showNewMessageIndicator ? 8 : 0) {
                    if showScrollToBottomIndicator {
                        Image(systemName: "chevron.down")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(.white)
                    }
                                    
                    if showNewMessageIndicator {
                        Text("New Messages")
                            .font(AppFonts.sfProMedium14)
                            .foregroundColor(AppColors.whiteOpacity95)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, showNewMessageIndicator ? 12 : 8) // Adjust padding based on state
                .background(AppColors.newMessageBlueBackgroundColor) // Matches theme
                .clipShape(showNewMessageIndicator ? AnyShape(Capsule()) : AnyShape(Circle()))
                .onTapGesture {
                    scrollToLastMessage()
                }
                
                Spacer()
            }
            .padding(.bottom, 100)
            .transition(.move(edge: .bottom))
        }
    }
    
    
    // MARK: - Scroll to Last Message
    
    private func scrollToLastMessage() {
        guard let lastMessage = conversationViewModel.sortedGroupedMessages.flatMap({ $0.value }).last else { return }
        
        // Wait for the view to settle before scrolling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                guard let proxyTest = self.scrollViewProxy else { return }
                proxyTest.scrollTo(lastMessage.transactionId, anchor: .bottom)
                showNewMessageIndicator = false
                showScrollToBottomIndicator = false
            }
        }
    }
    
    private func determineThreadType() -> InAppThreadType {
        return selectedThread.type
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        let message = InAppMessage()
        message.thread = selectedThread
        message.message = messageText
        conversationViewModel.publishMessageWith(message: message)
        messageText = ""
        if !showScrollToBottomIndicator {
            showNewMessageIndicator = false
            scrollToLastMessage()
        }
        
    }
    
    
}

struct MessageRowView: View {
    let message: InAppMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .frame(width: 44, height: 44)
                .overlay(
                    Image(message.isOutgoing ? "Avatar" : "agent_avatar") // Replace with actual image assets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                )

            VStack(alignment: .leading, spacing: 4) {
                // User/Agent Label with Timestamp
                HStack {
                    Text(message.isOutgoing ? "You" : "Agent")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(formatDate(message.submittedAt ?? message.createdAt ?? Date()))
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }

                // Message Text
                Text(message.message ?? "")
                    .font(.body)
                    .foregroundColor(.white)
            }

            if message.isOutgoing {
                Spacer()
            }
        }
        .padding(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 8))
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct GroupHeaderView: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.leading, 16)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray)
                .padding(.trailing, 16)
        }
        .padding(.vertical, 4)
        .background(Color.black)
    }
}


