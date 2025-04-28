//
//  InAppMessagingDelegateHandler.swift
//  WebexConnectDemo
//

import Foundation
import WebexConnectInAppMessaging

/// A class that handles in-app messaging events and updates the view model accordingly.
class InAppMessagingDelegateHandler<T: InAppMessagingViewModel>: NSObject, InAppMessagingDelegate {
    weak var viewModel: T?

    /// Initializes an instance of `InAppMessagingDelegateHandler` with the given `ThreadsViewModel`.
    ///
    /// - Parameter viewModel: The view model that will handle updates for in-app messages and connection status.
    init(viewModel: T) {
        self.viewModel = viewModel
    }

    /// Handles the reception of an incoming in-app message.
    ///
    /// This method appends the incoming message to the `viewModel.messages` array if it belongs to the active thread and is an incoming message (not outgoing).
    /// It then saves the message using the view model's `save(message:)` method.
    ///
    /// - Parameter message: The incoming `InAppMessage` object that was received.
    func didReceiveInAppMessage(_ message: InAppMessage) {
        guard let viewModel = viewModel else { return }
        if viewModel.threadId == message.thread?.id && message.isOutgoing == false{
            viewModel.messages.append(message) // To add the incoming messages instantly
        }
        viewModel.save(message: message)
    }

    /// Handles a change in connection status and forwards it to the `ThreadsViewModel`.
    ///
    /// - Parameter connectionStatus: The new connection status as an enum value of type `ConnectionStatus`.
    func didChangeConnectionStatus(_ connectionStatus: ConnectionStatus) {
        // Forward the status change to the view model if needed
        print("Connection status changed to: \(connectionStatus.rawValue)")
        DispatchQueue.main.async {
            self.viewModel?.connectionStatus = connectionStatus
        }
    }
}
