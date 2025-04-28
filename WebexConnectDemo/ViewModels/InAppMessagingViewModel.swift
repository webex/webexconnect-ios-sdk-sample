//
//  InAppMessagingViewModel.swift
//  WebexConnectDemo
//
import Foundation
import WebexConnectInAppMessaging

protocol InAppMessagingViewModel: ObservableObject {
    var messages: [InAppMessage] { get set }
    func save(message: InAppMessage)
    var threadId: String? { get set }
    var connectionStatus: ConnectionStatus? { get set }
}
