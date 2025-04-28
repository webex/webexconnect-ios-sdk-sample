//
//  ThreadsViewModel.swift
//  WebexConnectDemo
//
import SwiftUI
import WebexConnectInAppMessaging

/// ViewModel responsible for managing in-app messaging threads and messages.
class ThreadsViewModel: ObservableObject, InAppMessagingViewModel {
    var threadId: String?
       
    // WebexConnectSDK: Retrieve the shared InAppMessaging instance
    private let messaging: InAppMessaging = InAppMessagingProvider.instance
    
    // WebexConnectSDK: Retrieve the shared MessageStore instance
    private let store: MessageStore? = InAppMessagingProvider.instance.messageStore
    
    // MARK: - Published Properties
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var threads: [InAppThread] = []
    @Published var createdThreadId: String? // For navigation
    @Published var messages: [InAppMessage] = []
    @Published var connectionStatus: ConnectionStatus?
    
    // MARK: - State Variables
    var hasMoreLocalThreads: Bool = true
    var hasMoreRemoteThreads: Bool = true
    var threadListMessages: [InAppMessage] = []
    var triggerMessage: InAppMessage?
    var threadType: InAppThreadType = .conversation

    
    var tempThread: InAppThread?
    
    var transactionId: String = ""
    
    init() {
        setInAppDelegate()
        establishInAppMessagingConnection()
    }
    
    func clearMessages() {
        self.messages = []
        self.createdThreadId = nil
    }
    
    /// Fetches threads of a specific type.
    func loadConversarionsWith(type: InAppThreadType) {
        self.threadType = type
        self.hasMoreLocalThreads = true
        self.hasMoreRemoteThreads = true
        self.threads = []
        self.messages = []
        self.loadThreads()
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
    
    /// Creates a new in-app messaging thread.
    ///
    /// - Parameters:
    ///   - title: The title of the new thread.
    ///   - completion: A closure called with the created thread ID and title on success, or empty strings on failure.
    func createThread(with title: String, completion: @escaping (String, String) -> Void) {
        self.createdThreadId = nil
        self.tempThread = nil
        let thread = InAppThread()
        thread.title = title

        // WebexConnectSDK: Create a new thread.
        // The completion handler is invoked with the created thread on success, or an error if creation fails.
        messaging.createThread(thread) { thread, error in
            DispatchQueue.main.async {
                if let thread = thread, error == nil {
                    self.createdThreadId = thread.id
                    self.tempThread = thread
                    self.messages = []
                    print("Thread created with ID: \(thread.id)")
                    completion(thread.id ?? "", title)  // Call completion handler on success
                } else {
                    print("Failed to create thread: \(error?.localizedDescription ?? "Unknown error")")
                    completion("", "")  // Call completion handler on failure
                }
            }
        }
    }
    
    /// Loads threads from both local storage and remote API.
    func loadThreads() {
        self.loadMoreThreads(30, beforeDate: Date()) { threads, messages, error in
            if let error {
                self.threads = []
                self.messages = []
                print("error while loading the threads: \(error.localizedDescription)")
            } else {
                self.threads = threads ?? []
                self.messages = messages ?? []
            }
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
    
    
    
    /// Fetches the thread from the message store.
    ///
    /// - Returns: The InAppThread object if found, or nil if no thread is found in the store.
    func fetchThread() -> InAppThread? {
        // WebexConnectSDK: Load thread from the message store.
        if let store, let threadID = threadId, let thread = store.loadThread(withThreadId: threadID) {
            print("Loaded thread: \(formatThreadDetails(thread))")
            return thread
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
    
    /// Formats and returns a string representation of the thread's details.
    ///
    /// - Parameter thread: The `InAppThread` object to format.
    ///
    /// - Returns: A formatted string containing the thread's ID, title, creation date, update date, type, status, and category.
    private func formatThreadDetails(_ thread: InAppThread?) -> String {
        if let thread {
            return """
            ID: \(thread.id ?? "N/A")
            Title: \(thread.title ?? "N/A")
            Created At: \(thread.createdAt ?? Date())
            Updated At: \(thread.updatedAt ?? Date())
            Type: \(thread.type)
            Status: \(thread.status)
            Category: \(thread.category ?? "N/A")
            """
        } else {
            return ""
        }
    }
    
    /// Loads additional threads and messages, first from local storage, then remotely if necessary.
    ///
    /// - Parameters:
    ///   - numberOfThreads: The number of threads to load.
    ///   - beforeDate: The date before which threads should be loaded. Defaults to the current date.
    ///   - completionHandler: A closure that receives the loaded threads, messages, and any potential error.
    func loadMoreThreads(_ numberOfThreads: Int, beforeDate: Date? = nil, completionHandler: @escaping ([InAppThread]?, [InAppMessage]?, Error?) -> Void) {
        let fetchBeforeDate = beforeDate ?? Date()

        if hasMoreLocalThreads {
            loadMoreLocalThreads(numberOfThreads, beforeDate: fetchBeforeDate) { localThreads, localMessages, error in
                var threads = localThreads ?? []
                var messages = localMessages ?? []

                self.threads = threads
                self.messages = messages

                if threads.count < numberOfThreads {
                    var lastMessageDate = fetchBeforeDate
                    if let lastMessage = messages.first, let submittedAt = lastMessage.submittedAt {
                        lastMessageDate = submittedAt
                    }

                    self.hasMoreLocalThreads = false
                    // Now load from remote after local exhausted
                    self.loadMoreRemoteThreads(numberOfThreads - threads.count, beforeDate: lastMessageDate) { remoteThreads, remoteMessages, remoteError in
                        DispatchQueue.main.async {
                            if let remoteThreads = remoteThreads {
                                threads.append(contentsOf: remoteThreads)
                            }
                            if let remoteMessages = remoteMessages {
                                messages.append(contentsOf: remoteMessages)
                            }
                            
                            if (remoteThreads?.count ?? 0) < (numberOfThreads - threads.count) {
                                self.hasMoreRemoteThreads = false
                            }

                            self.threads = threads
                            self.messages = messages
                            completionHandler(threads, messages, remoteError)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completionHandler(threads, messages, error)
                    }
                }
            }
        } else if hasMoreRemoteThreads {
            // If local store is exhausted, fetch directly from remote
            loadMoreRemoteThreads(numberOfThreads, beforeDate: fetchBeforeDate) { remoteThreads, remoteMessages, remoteError in
                DispatchQueue.main.async {
                    self.threads = remoteThreads ?? []
                    self.messages = remoteMessages ?? []

                    if (remoteThreads?.count ?? 0) < numberOfThreads {
                        self.hasMoreRemoteThreads = false
                    }

                    completionHandler(remoteThreads, remoteMessages, remoteError)
                }
            }
        } else {
            // No more data to load
            DispatchQueue.main.async {
                completionHandler([], [], nil)
            }
        }
    }

    /// Loads more threads from local storage and retrieves the associated messages.
    ///
    /// - Parameters:
    ///   - numberOfThreads: The number of threads to load.
    ///   - beforeDate: The date before which threads should be loaded.
    ///   - completionHandler: A closure that receives the loaded threads, messages, and any potential error.
    private func loadMoreLocalThreads(_ numberOfThreads: Int, beforeDate: Date, completionHandler: @escaping ([InAppThread]?, [InAppMessage]?, Error?) -> Void) {
        guard let store = store else {
            let error = NSError(domain: "Message Store is not available", code: 0, userInfo: nil)
            completionHandler(nil, nil, error)
            return
        }
        let threads = store.loadThreads(updatedBefore: beforeDate, limit: numberOfThreads)
        let filteredThreads = threads.filter { $0.type == threadType }

        if !filteredThreads.isEmpty {
            var localMessages: [InAppMessage] = []
            for thread in filteredThreads {
                let messages = store.loadMessages(withThreadId: thread.id ?? "", submittedBefore: Date(), limit: 1)
                let message = messages.first ?? getMessageWith(thread: thread)
                localMessages.append(message)
            }
            if threads.count < numberOfThreads {
                hasMoreLocalThreads = false
            } else {
                triggerMessage = localMessages.last
            }
            completionHandler(filteredThreads, localMessages, nil)
        } else {
            hasMoreLocalThreads = false
            completionHandler(nil, nil, nil)
        }
    }
    
    /// Retrieves or creates a default message associated with the given thread.
    ///
    /// - Parameter thread: The thread for which the message is to be retrieved.
    /// - Returns: An `InAppMessage` object associated with the provided thread.
    private func getMessageWith(thread: InAppThread) -> InAppMessage {
        let message = InAppMessage()
        message.thread = thread
        return message
    }

    /// Loads more threads from the remote server and fetches their associated messages.
    ///
    /// - Parameters:
    ///   - numberOfThreads: The number of threads to load.
    ///   - beforeDate: The date before which threads should be loaded.
    ///   - completionHandler: A closure that receives the loaded threads, messages, and any potential error.
    private func loadMoreRemoteThreads(_ numberOfThreads: Int, beforeDate: Date, completionHandler: @escaping ([InAppThread]?, [InAppMessage]?, Error?) -> Void) {
        messaging.fetchThreads(beforeDate: beforeDate, limit: numberOfThreads, category: nil, threadType: threadType) { threads, hasMoreThreads, error in
            guard error == nil, !threads.isEmpty else {
                DispatchQueue.main.async {
                    completionHandler(nil, nil, error)
                }
                return
            }

            var pendingThreadCount = threads.count
            var remoteMessages: [InAppMessage] = []

            for thread in threads {
                self.messaging.fetchMessages(forThreadId: thread.id ?? "", beforeDate: Date(), limit: 10) { messages, hasMoreMessages, error in
                    pendingThreadCount -= 1
                    if let message = messages.first {
                        remoteMessages.append(message)
                    } else {
                        let message = InAppMessage()
                        message.thread = thread
                        remoteMessages.append(message)
                    }

                    if pendingThreadCount == 0 {
                        remoteMessages.sort { $0.submittedAt ?? Date() > $1.submittedAt ?? Date() }
                        if hasMoreThreads {
                            self.triggerMessage = remoteMessages.last
                        }
                        DispatchQueue.main.async {
                            completionHandler(threads, remoteMessages, nil)
                        }
                    }
                }
            }

            if threads.count < numberOfThreads {
                self.hasMoreRemoteThreads = false
                self.triggerMessage = nil
            }
        }
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
