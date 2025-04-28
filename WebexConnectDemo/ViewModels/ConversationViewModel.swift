//
//  ConversationViewModel.swift
//  WebexConnectDemo
//
import SwiftUI
import WebexConnectInAppMessaging

/// ViewModel responsible for managing in-app messaging threads and messages.
class ConversationViewModel: ObservableObject, InAppMessagingViewModel {
    var threadId: String?
    
    
    // MARK: - Dependencies
   
    // WebexConnectSDK: Retrieve the shared InAppMessaging instance
    private let messaging: InAppMessaging = InAppMessagingProvider.instance
    
    // WebexConnectSDK: Retrieve the shared MessageStore instance
    private let store: MessageStore? = InAppMessagingProvider.instance.messageStore
    
    // MARK: - Published Properties
    @Published var alertMessage = ""
    @Published var messages: [InAppMessage] = []
    @Published var connectionStatus: ConnectionStatus?
    
    // MARK: - State Variables
    var transactionId: String = ""
    
    init() {
        setInAppDelegate()
        establishInAppMessagingConnection()
    }
    
    /// Group messages by date for display, sorting them from oldest to newest.
    private var groupedMessages: [(key: String, value: [InAppMessage])] {
        let groupedDict = Dictionary(grouping: self.messages.sorted(by: {
            let firstMessageDate = $0.submittedAt ?? $0.createdAt ?? Date()
            let secondMessageDate = $1.submittedAt ?? $1.createdAt ?? Date()
            return firstMessageDate < secondMessageDate // Oldest first
        })) { message in
            let date = message.submittedAt ?? message.createdAt ?? Date()

            if Calendar.current.isDateInToday(date) {
                return "Today"
            } else if Calendar.current.isDateInYesterday(date) {
                let formattedDate = date.stringFromDate(format: "dd/MM/yyyy")
                return "Yesterday - \(formattedDate)"
            } else {
                let formattedDate = date.stringFromDate(format: "EEEE - dd/MM/yyyy")
                return formattedDate
            }
        }

        // Sort the dictionary keys (dates) in ascending order (oldest first)
        return groupedDict.sorted { first, second in
            guard let date1 = first.value.first?.submittedAt ?? first.value.first?.createdAt else { return false }
            guard let date2 = second.value.first?.submittedAt ?? second.value.first?.createdAt else { return true }
            return date1 < date2 // Oldest first
        }
    }
    
    /// Further sorts grouped messages by extracting and comparing their dates.
    var sortedGroupedMessages: [(key: String, value: [InAppMessage])] {
        groupedMessages.sorted { first, second in
            guard let date1 = extractDate(from: first.key),
                  let date2 = extractDate(from: second.key) else {
                return false
            }
            return date1 < date2 // Oldest first
        }
    }
    
    func clearMessages() {
        self.messages = []
    }
    
    /// Extracts a `Date` object from a given date string.
    private func extractDate(from key: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE - dd/MM/yyyy"
        
        if key == "Today" {
            return Date()
        } else if key.starts(with: "Yesterday") {
            return Calendar.current.date(byAdding: .day, value: -1, to: Date())
        } else {
            return dateFormatter.date(from: key)
        }
    }

    /// Sets up the delegate for in-app messaging.
    func setInAppDelegate() {
        let handler = InAppMessagingDelegateHandler(viewModel: self)
        /// WebexConnectSDK: Sets up the delegate for in-app messaging
        messaging.delegate = handler
    }
    
    /// Attempts to establish a connection for in-app messaging.
    func establishInAppMessagingConnection() {
        do {
            /// WebexConnectSDK: Tries to establish a connection with the WebexConnect platform in order to receive Real Time Messages.
            try messaging.connect()
        } catch {
            print("Error while connecting to InAppMessaging: \(error.localizedDescription)")
        }
    }
    
    /// Load messages from the local store first, and if no messages are found, fetch from the API.
       func loadAndFetchMessages(threadID: String) {
           // Load messages from local store
           if let localMessages = loadMessagesWith(threadID: threadID), !localMessages.isEmpty {
               self.messages = localMessages
           } else {
               // If no local messages, fetch from the API
               fetchMessagesWith(threadID: threadID)
           }
       }
       
    // WebexConnectSDK: Fetch messages from the server for a specific thread.
    ///
    /// - Parameter threadID: The ID of the thread from which messages will be fetched.
    func fetchMessagesWith(threadID: String) {
        // The completion handler returns an error if fetchMessages fails, or messages if successful.
        messaging.fetchMessages(forThreadId: threadID, beforeDate: Date(), limit: 100) { loadedMessages, hasLoaded, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.alertMessage = "Failed to load the messages: \(error.localizedDescription)"
                    self.messages = []
                } else {
                    if loadedMessages.isEmpty {
                        self.messages = []
                        self.alertMessage = "No messages available for this thread."
                    } else {
                        self.messages = loadedMessages
                        self.alertMessage = "Messages loaded successfully for thread \(threadID)."
                    }
                }
            }
        }
    }
       
    // WebexConnectSDK: Load messages from the message store
       func loadMessagesWith(threadID: String) -> [InAppMessage]? {
           if let store {
               return store.loadMessages(withThreadId: threadID, submittedBefore: Date(), limit: 100)
           }
           return nil
       }
    
    /// Publishes a new in-app message.
    ///
    /// - Parameter message: The message to be published.
    func publishMessageWith(message: InAppMessage) {
        messages.append(message)
        
        // WebexConnectSDK: Publish the message to the messaging system.
        messaging.publishMessage(message) { error in
            if let error {
                print("Error while publishing message: \(error.localizedDescription)")
            } else {
                print("Published message successfully")
            }
        }
    }
    
    /// Sends message status updates (e.g., read receipt) for the specified transaction IDs.
    ///
    /// - Parameter transactionIds: An array of transaction IDs for which the status is to be sent.
    func sendMessageStatusFor(transactionIds: [String]) {
        guard !transactionIds.isEmpty else  {
            print("Please pass valid transaction IDs.")
            return
        }
        
        let completionHandler: (Error?) -> Void = { error in
            if error == nil {
                print("Status sent successfully.")
            } else {
                print("Failed to send the status. \(String(describing: error))")
            }
        }
        
        // WebexConnectSDK: Send the message status (read receipt) for the specified transaction IDs.
        if transactionIds.count > 1 {
            messaging.sendMessageStatus(for: transactionIds, status: .read, completionHandler: completionHandler)
        } else {
            messaging.sendMessageStatus(for: transactionIds.first ?? "", status: .read, button: nil, completionHandler: completionHandler)
        }
    }
    
    /// Saves the given message to the message store.
    ///
    /// - Parameter message: The InAppMessage object to be saved.
    func save(message: InAppMessage) {
        guard let store = store else { return }
        let messageStored = store.saveMessages([message])
        print("Message stored successfully: \(messageStored)")
    }
    
    /// Sends read receipts for unread messages.
    ///
    /// This method filters incoming messages that are not marked as outgoing and have not yet been read,
    /// and sends their transaction IDs as read receipts.
    func sendReadReceipts() {
        let incomingMessages = messages.filter({ $0.isOutgoing == false })
        let unreadMessages = incomingMessages.filter({ $0.readAt == nil })
        let unreadTransactionIds = unreadMessages.compactMap({$0.transactionId})
        self.sendMessageStatusFor(transactionIds: unreadTransactionIds)
    }

}
